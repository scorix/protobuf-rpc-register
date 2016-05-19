module Protobuf
  module Rpc
    class Serializer
      def self.dump(msg, serializer = nil)
        return msg if msg.is_a?(Messages::RpcCompressedMessage)
        dumped_message = Messages::RpcCompressedMessage.new(compressed: false)

        # serialize the message
        case msg
          when ::Protobuf::Message
            proto(dumped_message, msg)
          when StandardError
            error = Messages::Error.new(error_class: msg.class.name,
                                        error_message: msg.message,
                                        error_backtrace: msg.backtrace)
            proto(dumped_message, error)
          else
            case serializer.to_s.upcase.to_sym
              when :MSGPACK
                msgpack(dumped_message, msg)
              when :OJ
                oj(dumped_message, msg)
              when :MULTI_JSON
                multi_json(dumped_message, msg)
              when :JSON
                json(dumped_message, msg)
              when :YAML
                yaml(dumped_message, msg)
              when :MARSHAL
                marshal(dumped_message, msg)
              when :RAW
                raw(dumped_message, msg)
              else
                if defined?(MessagePack) && msg.respond_to?(:to_msgpack)
                  msgpack(dumped_message, msg)
                elsif defined?(Oj)
                  oj(dumped_message, msg)
                elsif defined?(MultiJson)
                  multi_json(dumped_message, msg)
                else
                  yaml(dumped_message, msg)
                end
            end
        end

        dumped_message.compressed = true if msg.is_a?(String)
        dumped_message.response_body = ActiveSupport::Gzip.compress(dumped_message.response_body) if dumped_message.compressed
        dumped_message
      end

      def self.load(msg)
        return msg unless msg.is_a?(Messages::RpcCompressedMessage)
        body = msg.compressed ? ActiveSupport::Gzip.decompress(msg.response_body) : msg.response_body

        if msg.response_type.present?
          Object.const_get(msg.response_type).decode(body)
        else
          case msg.serializer.name
            when :RAW
              body
            when :MSGPACK
              require 'msgpack'
              MessagePack.unpack(body)
            when :MARSHAL
              Marshal.load(body)
            when :JSON
              begin
                require 'multi_json'
                MultiJson.load(body)
              rescue LoadError
                require 'json'
                JSON.parse(body)
              end
            when :YAML
              require 'yaml'
              YAML.load(body)
            else
              body
          end
        end
      end

      class << self
        private
        def proto(dumped_message, msg)
          dumped_message.compressed = true
          dumped_message.response_type = msg.class.name
          dumped_message.response_body = msg.bytes
          dumped_message.serializer = :RAW
        end

        def msgpack(dumped_message, msg)
          dumped_message.response_body = msg.to_msgpack
          dumped_message.serializer = :MSGPACK
        end

        def yaml(dumped_message, msg)
          require 'yaml' unless msg.respond_to?(:to_yaml)
          dumped_message.response_body = msg.to_yaml
          dumped_message.serializer = :YAML
        end

        def oj(dumped_message, msg)
          dumped_message.response_body = Oj.dump(msg)
          dumped_message.serializer = :JSON
        end

        def multi_json(dumped_message, msg)
          dumped_message.response_body = MultiJson.dump(msg)
          dumped_message.serializer = :JSON
        end

        def marshal(dumped_message, msg)
          dumped_message.response_body = Marshal.dump(msg)
          dumped_message.serializer = :MARSHAL
        end

        def json(dumped_message, msg)
          require 'json' unless msg.respond_to?(:to_json)
          dumped_message.response_body = msg.to_json
          dumped_message.serializer = :JSON
        end

        def raw(dumped_message, msg)
          dumped_message.response_body = msg
          dumped_message.serializer = :RAW
        end
      end
    end
  end
end
