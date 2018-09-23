module Monus::BuiltInMetric
  @@metrics = {}

  def self.register(name, object)
    @@metrics[name] = object
  end

  def self.[](name)
    @@metrics[name] or raise NotImplementedError, "no such metric: #{name.inspect}, possible metrics are: #{@@metrics.keys.map(&:inspect) * ', '}"
  end
end

metrics_glob = File.join File.dirname(__FILE__), 'built_in_metrics', '*.rb'
metrics_files = Dir[metrics_glob].map &File.method(:absolute_path)
metrics_files.each &method(:require)