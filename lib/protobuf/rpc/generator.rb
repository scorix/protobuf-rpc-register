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
        @services[service] ||= "#{@module}::Services::#{service}".safe_constantize ||
            @module::Services.const_set(service, Class.new(Protobuf::Rpc::Services::Base))
      end

      def define_client_class(service)
        @module.const_set(:Clients, Module.new) unless @module.const_defined?(:Clients)
        @clients[service] ||= "#{@module}::Clients::#{service}".safe_constantize ||
            @module::Clients.const_set(service, Class.new(Protobuf::Rpc::Clients::Base))
        @services[service].rpcs.keys.each { |m| @clients[service].implement_rpc(m) }
      end
    end
  end
end
