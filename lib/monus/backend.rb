module Monus::Backend
  @@backends = {}

  def self.register(name, object)
    @@backends[name] = object
  end

  def self.[](name)
    @@backends[name] or raise NotImplementedError, "no such backend: #{name.inspect}, possible backends are: #{@@backends.keys.map(&:inspect) * ', '}"
  end
end

backends_glob = File.join File.dirname(__FILE__), 'backends', '*.rb'
backends_files = Dir[backends_glob].map &File.method(:absolute_path)
backends_files.each &method(:require)