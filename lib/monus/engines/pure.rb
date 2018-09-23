module Monus::Engine::Pure
  def initialize_defaults
    @on_error ||= []
  end

  def prepare
    initialize_defaults
    option = Monus.options.dig(:pure_engine_options, :on_async_error)
    case option
    when Array
      option.each &method(:add_error_handler)
    else
      add_error_handler option
    end
    @prepared = true
  end

  def add_error_handler(handler)
    initialize_defaults
    @on_error.push case handler
    when Proc
      handler
    when :crash
      -> * { exit 1 }
    when :ignore
      -> * {}
    when :break
      -> error, * { raise error }
    when :log, nil
      -> error, type, * { Monus.logger.fatal "error in Monus #{type} - #{error.class}: #{error.message}\n#{error.backtrace * "\n"}" }
    else
      raise Monus::ConfigurationError, 'unknown error handler given in `pure_engine_options/on_async_error` configuration; it should be a block (exception, type and binding arguments will passed) or one of `:crash`, `:ignore`, `:break` or `:log` (default) values, or array of them'
    end
  end

  def make_http_connection(host, port)
    load_http
    Net::HTTP.start host, port
  end

  def send_http_request(uri, method: :get, body: nil, connection: Net::HTTP)
    load_http
    uri = URI.parse uri if connection == Net::HTTP and not uri.kind_of?(URI)
    case method
    when :get then connection.get uri
    when :post then connection.post uri, body
    else raise NotImplementedError, "unknown HTTP method #{method.inspect}"
    end
  end

  def load_http
    @http_loaded ||= begin
      require 'net/http'
      require 'uri'
      true
    end
  end

  def send_udp_datagram(message, host, port)
    @udp_socket ||= begin
      require 'socket'
      UDPSocket.new
    end
    @udp_socket.send message, 0, host, port
  end

  def every(interval, fire_immediately: true, on_error: nil, &block)
    prepare unless @prepared

    Thread.new do
      sleep interval unless fire_immediately

      loop do
        begin
          block.call
        rescue => error
          interval_binding = binding
          Array(on_error || @on_error).each do |handler|
            handler.call error, :interval, interval_binding
          end
        end
        sleep interval
      end
    end
  end

  extend self

  Monus::Engine.register :pure, self
end