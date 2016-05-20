module Protobuf
  module Rpc
    RSpec.describe Generator do
      before { Protobuf::Rpc::Generator.new(TestRpc).generate(:Version, with: [:message]) }

      context :client do

        subject { TestRpc::Clients::Version.new }
        before { allow(subject).to receive(:send_rpc_request).and_return(true) }
        it { is_expected.to respond_to :message }

        context :default do
          its(:message) { is_expected.to eql true }
        end

        context :version do
          it { expect(subject.message(version: '1')).to eql true }
        end

        context :protobuf_message do
          class CustomVersionMessage < ::Protobuf::Message
            optional :uint32, :version, 999
          end
          it { expect(subject.message(CustomVersionMessage.new(version: 1))).to eql true }
        end
      end

      context :service do
        subject { TestRpc::Services::Version }
        its(:rpcs) { is_expected.to include :message }
      end
    end
  end
end
