module Protobuf
  module Rpc
    module Clients
      class Base
        attr_accessor :logger

        def initialize(options = {})
          @options = options
          @logger ||= Logger.new(STDOUT)
        end

        def send_rpc_request(method, msg)
          res = nil

          names = self.class.name.split('::')
          svc_class = [names[0..-3], 'Services', names[-1]].flatten.join('::')

          Object.const_get(svc_class).client(@options).send(method, pack(msg)) do |c|
            c.on_success do |rpc_compressed_message|
              res = unpack(rpc_compressed_message)
            end

            c.on_failure do |error|
              exception_name = Protobuf::Socketrpc::ErrorReason.name_for_tag(error.code).to_s.downcase
              exception_class = Protobuf::Rpc.const_get(exception_name.camelize)
              exception = exception_class.new(error.message)
              logger.error exception
              raise exception
            end
          end

          if res.is_a?(Messages::Error)
            error = res.error_class.constantize.new(res.error_message)
            error.set_backtrace(res.error_backtrace)
            logger.error error
            raise error
          else
            res
          end
        end

        def pack(rpc_uncompressed_message)
          msg = rpc_uncompressed_message
          case msg
            when ::Protobuf::Message
              msg = {compressed: true,
                     response_type: msg.class.name,
                     response_body: ActiveSupport::Gzip.compress(msg.bytes),
                     serializer: :RAW}
            when String
              msg = {compressed: true,
                     response_type: nil,
                     response_body: ActiveSupport::Gzip.compress(msg.to_msgpack),
                     serializer: :MSGPACK}
            else
              msg = {compressed: false,
                     response_type: nil,
                     response_body: msg.to_msgpack,
                     serializer: :MSGPACK}
          end
          Protobuf::Rpc::Messages::RpcCompressedMessage.new(msg)
        end

        def unpack(rpc_compressed_message)
          decompressed_body = if rpc_compressed_message.compressed
                                ActiveSupport::Gzip.decompress(rpc_compressed_message.response_body)
                              else
                                rpc_compressed_message.response_body
                              end

          if rpc_compressed_message.response_type.present?
            Object.const_get(rpc_compressed_message.response_type).decode(decompressed_body)
          else
            case rpc_compressed_message.serializer.name
              when :RAW
                decompressed_body
              when :MSGPACK
                MessagePack.unpack(decompressed_body)
              when :MARSHAL
                Marshal.load(decompressed_body)
              when :JSON
                MultiJson.load(decompressed_body)
              when :YAML
                YAML.load(decompressed_body)
              else
                decompressed_body
            end
          end
        end

        def self.implement_rpc(rpc_method)
          define_method(rpc_method) do |*args|
            names = self.class.name.split('::')
            msg_class = [names[0..-3], 'Messages', names[-1]].flatten.join('::')
            send_rpc_request(rpc_method, Object.const_get(msg_class).new(*args))
          end
        end
      end
    end
  end
end
