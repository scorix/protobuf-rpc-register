module Protobuf
  module Rpc
    module Clients
      class Base
        attr_accessor :logger, :error_logger
        attr_accessor :host, :port, :timeout

        mattr_reader(:mutex) { Mutex.new }

        def initialize(host: nil, port: nil, timeout: 1, stdout: STDOUT, stderr: STDERR, namespace: nil)
          @host = host
          @port = port
          @timeout = timeout
          @namespace = namespace
          @logger ||= Logger.new(stdout)
          @error_logger ||= Logger.new(stderr)
        end

        def send_rpc_request(method, msg, serializer:)
          res = nil

          internal_client.send(method, Serializer.dump(msg, serializer: serializer)) do |c|
            c.on_success do |rpc_compressed_message|
              res = Protobuf::Rpc::Serializer.load(rpc_compressed_message)
            end

            c.on_failure do |error|
              res = error
            end
          end

          check_response_error(res)
        end

        def check_response_error(res, raise_error: true)
          case res
            when Protobuf::Rpc::Messages::Error
              error_class = self.class.mutex.synchronize { define_error_class(res) }
              error = error_class.new(res.error_message)
              error.set_backtrace(res.error_backtrace)
              raise_error(error, raise_error)
            when Protobuf::Error
              error_reason = Protobuf::Socketrpc::ErrorReason.name_for_tag(res.code).to_s.downcase
              error_class = Protobuf::Rpc.const_get(error_reason.camelize)
              error = error_class.new(res.message)
              raise_error(error, raise_error)
            else
              res
          end
        end

        private

        def internal_client
          @internal_client ||= begin
            names = self.class.name.split('::')
            svc_class = [names[0..-3], 'Services', names[-1]].flatten.join('::')
            Object.const_get(svc_class).client(host: host, port: port, timeout: timeout)
          end
        end

        def define_error_class(res)
          module_name = (@namespace || 'Protobuf').camelize
          m = Object.const_defined?(module_name, false) ? Object.const_get(module_name, false) : Object.const_set(module_name, Module.new)
          m.const_defined?(:Rpc, false) ? m.const_get(:Rpc, false) : m.const_set(:Rpc, Module.new)

          if m.const_defined?(res.error_class, false)
            m.const_get(res.error_class, false)
          else
            module_name = res.error_class.deconstantize
            class_name = res.error_class.demodulize
            base_module = m::Rpc
            module_name.split('::').each do |m|
              base_module.const_defined?(m, false) || base_module.const_set(m, Module.new)
              base_module = base_module.const_get(m, false)
            end
            error_superclass = res.error_class.safe_constantize || begin
              require res.error_class.split('::')[0].underscore
              res.error_class.constantize
            rescue LoadError
              raise NameError.new("uninitialized constant #{res.error_class}", res.error_class)
            end
            if base_module.const_defined?(class_name, false)
              base_module.const_get(class_name, false)
            else
              base_module.const_set(class_name, Class.new(error_superclass) do
                def initialize(message = nil)
                  @message = message
                end

                def inspect
                  "#{self.class}: #{@message}"
                end

                def message
                  @message
                end
              end)
            end
          end
        end

        def raise_error(error, raise_error = false)
          raise_error ? raise(error) : error_logger.error(error)
          error
        end

        def self.implement_rpc(rpc_method)
          define_method(rpc_method) do |*args|
            names = self.class.name.split('::')
            msg_class_name = [names[0..-3], 'Messages', names[-1]].flatten.join('::')

            msg = if args.first.is_a?(Protobuf::Message)
                    args.shift
                  elsif Object.const_defined?(msg_class_name, false)
                    msg_class = Object.const_get(msg_class_name)
                    msg_class.new(*args)
                  elsif args.first.respond_to?(:to_hash)
                    Messages::RpcCompressedMessage.new(response_body: ActiveSupport::Gzip.compress(args.first.to_hash.to_json),
                                                       serializer: :JSON,
                                                       compressed: true)
                  else
                    raise ArgumentError, "#{args} should be be a Hash or Protobuf Message."
                  end

            response = send_rpc_request(rpc_method, msg, serializer: :JSON)

            if response.class.name == msg_class_name.pluralize
              m = self.class.name.demodulize.underscore.pluralize.to_sym
              response.respond_to?(m) ? response.public_send(m) : response
            else
              response
            end
          end
        end
      end
    end
  end
end
