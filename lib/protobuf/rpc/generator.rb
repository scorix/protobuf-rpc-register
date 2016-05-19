module Protobuf
  module Rpc
    class Generator
      def initialize(mod)
        @mutex = Mutex.new
        @services = {}
        @clients = {}
        @module = mod
      end

      def generate(service, with: [])
        @mutex.synchronize do
          define_service_class(service)
          with.each { |m| @services[service].define_rpc(m) }
          define_client_class(service)
        end
        self
      end

      private
      def define_service_class(service)
        @module.const_set(:Services, Module.new) unless @module.const_defined?(:Services, false)
        @services[service] ||= if @module::Services.const_defined?(service, false)
                                 @module::Services.const_get(service, false)
                               else
                                 @module::Services.const_set(service, Class.new(Protobuf::Rpc::Services::Base))
                               end
      end

      def define_client_class(service)
        @module.const_set(:Clients, Module.new) unless @module.const_defined?(:Clients)
        @clients[service] ||= if @module::Clients.const_defined?(service, false)
                                @module::Clients.const_get(service, false)
                              else
                                @module::Clients.const_set(service, Class.new(Protobuf::Rpc::Clients::Base))
                              end
        @services[service].rpcs.keys.each { |m| @clients[service].implement_rpc(m) }
      end
    end
  end
end
