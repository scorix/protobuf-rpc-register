# NOTE: please require this file in your app config file:
# require 'protobuf/rpc/interaction_instrumentation'
DependencyDetection.defer do
  @name = :active_interaction

  depends_on do
    defined?(ActiveInteraction) && defined?(ActiveInteraction::Base)
  end

  executes do
    ::NewRelic::Agent.logger.info 'Installing ActiveInteraction instrumentation'
    require 'new_relic/agent/instrumentation/controller_instrumentation'
  end

  executes do
    class ActiveInteraction::Base
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation
      add_transaction_tracer :run
    end
  end
end
