module Protobuf
  module Rpc
    module Services
      class TestService < Base
      end
    end

    module Clients
      class TestService < Base
      end

      RSpec.describe Base do

        context :check_response_error do

          let(:client) { TestService.new(stdout: nil, stderr: nil) }
          subject { client.check_response_error(message, raise_error: false) }

          context :protobuf_message do
            let(:message) { Protobuf::Message.new }
            it { is_expected.to eq message }
          end

          context :string do
            let(:message) { 'Protobuf::Message.new' }
            it { is_expected.to eq message }
          end

          context :fixnum do
            let(:message) { 1 }
            it { is_expected.to eq message }
          end

          context :true do
            let(:message) { true }
            it { is_expected.to eq message }
          end

          context :error do
            let(:message) { StandardError.new }
            it { is_expected.to be_a StandardError }
          end

        end

      end
    end
  end
end
