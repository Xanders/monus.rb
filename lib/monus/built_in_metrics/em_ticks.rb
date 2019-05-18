module Monus::BuiltInMetric::EmTicks
  def activate
    @interval = Monus.options.dig(:em_ticks_metric_options, :interval) || 1

    counter, time = 0, Time.now

    @tick_loop = EM.tick_loop do
      counter += 1
      delta = Time.now - time
      if delta > @interval
        ticks = (counter.to_f / delta).round
        Fiber.new { Monus.set :em_ticks, ticks }.resume
        counter = 0
        time = Time.now
      end
    end
  end

  extend self

  Monus::BuiltInMetric.register :em_ticks, self
end