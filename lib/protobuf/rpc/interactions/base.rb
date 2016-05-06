require 'active_interaction'

module Protobuf
  module Rpc
    module Interactions
      class Base < ::ActiveInteraction::Base
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
