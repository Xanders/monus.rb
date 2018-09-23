module Monus
  ConfigurationError = Class.new StandardError

  @@prepared = false
  @@preparing = false
  @@options = {}

  def self.configure(options)
    @@options = options
    prepare
  end

  def self.options
    @@options
  end

  def self.prepare
    return true if @@prepared or @@preparing
    @@preparing = true

    @@engine = Monus::Engine[options[:engine] || :pure]
    @@engine.prepare

    @@backend = Monus::Backend[options[:backend] || :memory]
    @@backend.prepare

    options[:built_in_metrics]&.each do |metric|
      Monus::BuiltInMetric[metric].activate
    end

    @@preparing = false
    @@prepared = true
  end

  def self.engine
    prepare unless @@prepared
    @@engine
  end

  def self.backend
    prepare unless @@prepared
    @@backend
  end

  def self.logger
    @@logger ||= options[:logger] || begin
      require 'logger'
      Logger.new STDOUT
    end
  end

  def self.set(field, value)
    backend.write field, value
  end

  def self.accept(field)
    set field, true
  end

  def self.refuse(field)
    set field, false
  end
end

require_relative 'monus/engine'
require_relative 'monus/backend'
require_relative 'monus/built_in_metric'