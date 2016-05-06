module Protobuf
  module Rpc
    RSpec.describe Serializer do
      context :dump do
        subject { Serializer.dump(message) }

        context :protobuf_message do
          let(:message) { Protobuf::Message.new }
          it { is_expected.to be_a Messages::RpcCompressedMessage }
          its('serializer.name') { is_expected.to eql :RAW }
          its(:response_type) { is_expected.to eql 'Protobuf::Message' }
          its(:compressed) { is_expected.to be true }
        end

        context :string do
          let(:message) { 'Protobuf::Message.new' }
          it { is_expected.to be_a Messages::RpcCompressedMessage }
          its(:response_type) { is_expected.to be_blank }
          its(:compressed) { is_expected.to be true }
        end

        context :fixnum do
          let(:message) { 1 }
          it { is_expected.to be_a Messages::RpcCompressedMessage }
          its(:response_type) { is_expected.to be_blank }
          its(:compressed) { is_expected.to be false }
        end

        context :true do
          let(:message) { true }
          it { is_expected.to be_a Messages::RpcCompressedMessage }
          its(:response_type) { is_expected.to be_blank }
          its(:compressed) { is_expected.to be false }
        end

        context :error do
          let(:message) { StandardError.new }
          it { is_expected.to be_a Messages::RpcCompressedMessage }
          its(:response_type) { is_expected.to eql 'Protobuf::Rpc::Messages::Error' }
          its(:compressed) { is_expected.to be true }
        end


        context :serializer do
          subject { Serializer.dump(message, described_class) }
          let(:message) { 'Protobuf::Message.new' }
          shared_examples :serialize_as do |serializer_name|
            before do
              begin
                require described_class.to_s
              rescue LoadError
              end
            end
            it { is_expected.to be_a Messages::RpcCompressedMessage }
            its('serializer.name') { is_expected.to eql serializer_name }
            its(:response_type) { is_expected.to be_blank }
            its(:compressed) { is_expected.to be true }
          end
          context(:msgpack) { include_examples :serialize_as, :MSGPACK }
          context(:yaml) { include_examples :serialize_as, :YAML }
          context(:marshal) { include_examples :serialize_as, :MARSHAL }
          context(:oj) { include_examples :serialize_as, :JSON }
          context(:multi_json) { include_examples :serialize_as, :JSON }
          context(:raw) { include_examples :serialize_as, :RAW }
          context(:json) { include_examples :serialize_as, :JSON }
        end
      end

      context :load do
        subject { Serializer.load(message) }

        shared_examples :deserialize_as do |serializer, body, result|
          context :compressed do
            let(:message) { Messages::RpcCompressedMessage.new(serializer: serializer,
                                                               response_body: body,
                                                               compressed: false) }
            it { is_expected.to eql result }
          end

          context :uncompressed do
            let(:message) { Messages::RpcCompressedMessage.new(serializer: serializer,
                                                               response_body: ActiveSupport::Gzip.compress(body),
                                                               compressed: true) }
            it { is_expected.to eql result }
          end
        end

        context(:msgpack) { include_examples :deserialize_as, :MSGPACK, "\x01", 1 }
        context(:json) { include_examples :deserialize_as, :JSON, "1", 1 }
        context(:yaml) { include_examples :deserialize_as, :YAML, "--- 1\n...\n", 1 }
        context(:marshal) { include_examples :deserialize_as, :MARSHAL, "\x04\bi\x06", 1 }
        context(:raw) { include_examples :deserialize_as, :RAW, "1", "1" }
      end
    end
  end
end
