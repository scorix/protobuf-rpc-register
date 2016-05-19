require 'active_interaction'

module Protobuf
  module Rpc
    module Interactions
      class Base < ::ActiveInteraction::Base
        def presence_inputs
          # todo: need more fields to let server know specified nil values, otherwise it will be ignored
          inputs.reject { |k, v| !given?(k) && v.nil? }
        end

        def self.except_attributes
          [].freeze
        end

        def self.include_attributes
          [].freeze
        end
      end
    end
  end
end
