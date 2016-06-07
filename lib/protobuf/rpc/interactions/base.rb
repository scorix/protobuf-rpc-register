require 'active_interaction'

module Protobuf
  module Rpc
    module Interactions
      class Base < ::ActiveInteraction::Base

        def presence_inputs
          # todo: need more fields to let server know specified nil values, otherwise it will be ignored
          inputs.reject { |k, v| !given?(k) && v.nil? }
        end

        class << self
          def except_attributes
            [].freeze
          end

          def include_attributes
            [].freeze
          end

          private

          def inherited(subclass)
            super
            require 'new_relic/agent'
            subclass.include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
            subclass.include ::NewRelic::Agent::MethodTracer
            subclass.add_method_tracer :run
            subclass.add_transaction_tracer :run
          end
        end
      end
    end
  end
end
