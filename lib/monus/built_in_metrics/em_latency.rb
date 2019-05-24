module Monus::BuiltInMetric::EmLatency
  def activate
    unless Monus.engine.kind_of? Monus::Engine::EventMachine
      raise LoadError, 'in order to use em_latency metric you should use :eventmachine engine'
    end

    @interval = Monus.options.dig(:em_latency_metric_options, :interval) || 1

    last_time, current_time = nil, nil

    Monus.engine.every @interval do
      current_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      if last_time
        latency = current_time - last_time - @interval

        Monus.set :em_latency, latency
      end

      last_time = current_time
    end
  end

  extend self

  Monus::BuiltInMetric.register :em_latency, self
end