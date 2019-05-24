module Monus::BuiltInMetric::EmCallbacks
  def activate
    @interval = Monus.options.dig(:em_callbacks_metric_options, :interval) || 1

    begin
      require 'lspace/eventmachine'
    rescue LoadError
      raise LoadError, 'in order to use em_callbacks metric you should add `lspace` gem to your Gemfile'
    end

    timings = []

    LSpace.around_filter do |&block|
      time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin
        block.call
      ensure
        delta = Process.clock_gettime(Process::CLOCK_MONOTONIC) - time
        timings.push(delta)
      end
    end

    Monus.engine.every @interval do
      slice = timings.slice!(0..-1)

      next if slice.empty?

      number = slice.size
      maximum = slice.max
      total = slice.sum

      Monus.write em_callbacks_number: number,
                  em_callbacks_maximum: maximum,
                  em_callbacks_total: total
    end
  end

  extend self

  Monus::BuiltInMetric.register :em_callbacks, self
end