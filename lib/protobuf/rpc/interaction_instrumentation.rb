require 'new_relic/agent/instrumentation/action_controller_subscriber'

DependencyDetection.defer do
  @name = :active_interaction

  depends_on do
    defined?(ActiveInteraction) && defined?(ActiveInteraction::Base)
  end

  executes do
    ::NewRelic::Agent.logger.info 'Installing ActiveInteraction instrumentation'
  end

  executes do
    class ActiveInteraction::Base
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation
      add_transaction_tracer :run
    end
  end
end
