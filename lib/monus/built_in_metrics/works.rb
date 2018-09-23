module Monus::BuiltInMetric::Works
  def activate
    @interval = Monus.options.dig(:works_metric_options, :interval) || 1

    Monus.engine.every @interval do
      Monus.accept :works
    end
  end

  extend self

  Monus::BuiltInMetric.register :works, self
end