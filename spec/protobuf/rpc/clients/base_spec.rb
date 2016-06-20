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

          context :protobuf_error do
            context :case_1 do
              let(:message) { ::Protobuf::Rpc::Messages::Error.new(error_class: "NameError") }
              it { is_expected.to be_a ::NameError }
              its(:class) { is_expected.to_not eql ::NameError }
            end

            context :case_2 do
              let(:message) { ::Protobuf::Rpc::Messages::Error.new(error_class: "Protobuf::Rpc::PbError") }
              it { is_expected.to be_a ::Protobuf::Rpc::PbError }
              its(:class) { is_expected.to eql ::Protobuf::Rpc::PbError }
            end

            context :case_3 do
              let(:message) { ::Protobuf::Rpc::Messages::Error.new(error_class: "ActiveInteraction::InvalidValueError") }
              its("class.name") { is_expected.to eql "Protobuf::Rpc::ActiveInteraction::InvalidValueError" }
            end
          end

        end

      end
    end
  end
end
