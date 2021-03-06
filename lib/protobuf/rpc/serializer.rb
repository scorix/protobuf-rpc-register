module Protobuf
  module Rpc
    class Serializer
      def self.dump(msg, serializer:)
        return msg if msg.is_a?(::Protobuf::Rpc::Messages::RpcCompressedMessage)
        dumped_message = ::Protobuf::Rpc::Messages::RpcCompressedMessage.new(compressed: false)

        # serialize the message
        case msg
          when ::Protobuf::Message
            proto(dumped_message, msg)
          when StandardError
            error = ::Protobuf::Rpc::Messages::Error.new(error_class: msg.class.name,
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
              else
                raw(dumped_message, msg)
            end
        end

        # if size is greater than 16k, compress it
        if dumped_message.response_body.size > 16384
          dumped_message.compressed = true if msg.is_a?(String)
          dumped_message.response_body = ActiveSupport::Gzip.compress(dumped_message.response_body) if dumped_message.compressed
        else
          dumped_message.compressed = false
        end

        dumped_message
      end

      def self.load(msg)
        return msg unless msg.is_a?(::Protobuf::Rpc::Messages::RpcCompressedMessage)
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
          require 'msgpack' unless msg.respond_to?(:to_msgpack)
          dumped_message.response_body = msg.to_msgpack
          dumped_message.serializer = :MSGPACK
        end

        def yaml(dumped_message, msg)
          require 'yaml' unless msg.respond_to?(:to_yaml)
          dumped_message.response_body = msg.to_yaml
          dumped_message.serializer = :YAML
        end

        def oj(dumped_message, msg)
          require 'oj' unless defined?(:Oj)
          dumped_message.response_body = Oj.dump(msg)
          dumped_message.serializer = :JSON
        end

        def multi_json(dumped_message, msg)
          require 'multi_json' unless defined?(:MultiJson)
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
