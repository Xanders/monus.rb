module Monus::Engine
  @@engines = {}

  def self.register(name, object)
    @@engines[name] = object
  end

  def self.[](name)
    @@engines[name] or raise NotImplementedError, "no such engine: #{name.inspect}, possible engines are: #{@@engines.keys.map(&:inspect) * ', '}"
  end
end

engines_glob = File.join File.dirname(__FILE__), 'engines', '*.rb'
engines_files = Dir[engines_glob].map &File.method(:absolute_path)
engines_files.each &method(:require)