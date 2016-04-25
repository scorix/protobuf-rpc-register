module Protobuf
  module Rpc
    module Services
      class Base < ::Protobuf::Rpc::Service

        def compress_with(msg)
          case msg
            when ::Protobuf::Message
              respond_with compressed: true,
                           response_type: msg.class.name,
                           response_body: ActiveSupport::Gzip.compress(msg.bytes),
                           serializer: :RAW
            when String
              respond_with compressed: true,
                           response_type: nil,
                           response_body: ActiveSupport::Gzip.compress(msg.to_msgpack),
                           serializer: :MSGPACK
            else
              respond_with compressed: false,
                           response_type: nil,
                           response_body: msg.to_msgpack,
                           serializer: :MSGPACK
          end
        end

        def self.inherit_rpcs!
          superclass.rpcs.keys.each { |x| define_rpc(x, superclass.msgclass) }
        end

        def self.define_rpc(method, req = ::Protobuf::Rpc::Messages::RpcCompressedMessage, res = ::Protobuf::Rpc::Messages::RpcCompressedMessage)
          self.rpc method, req, res

          define_method(method) do
            class_name = method.to_s.camelize.gsub('!', 'Bang').gsub('?', 'QuestionMark')
            result = nil

            begin
              interaction = Interactions.const_get(name.demodulize).const_get(class_name)
            rescue NameError => e
              result = Protobuf::Rpc::MethodNotFound.new(e.message)
            end

            result || begin
              result = interaction.run!(request.to_hash)
              case result
                when Protobuf::Message
                  result
                when ActiveRecord::Base, ActiveRecord::Relation
                  result = result.to_proto(deprecated: false, except: interaction.except_attributes, include: interaction.include_attributes)
                else
                  result.respond_to?(:to_proto) ? result.to_proto : result
              end
            rescue => e
              result = Messages::Error.new(error_class: e.class.name, error_message: e.message, error_backtrace: e.backtrace)
            end

            compress_with result
          end
        end
      end
    end
  end
end
