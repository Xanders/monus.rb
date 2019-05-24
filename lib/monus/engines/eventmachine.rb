module Monus::Engine::EventMachine
  def prepare
    @prepared = true
  end

  def make_http_connection(host, port)
    load_http
    EM::HttpRequest.new("http://#{host}:#{port}")
  end

  def send_http_request(uri, method: :get, body: nil, connection: nil)
    load_http
    EM.schedule do
      if connection
        connection.setup_request(method, path: uri, keepalive: true)
      else
        EM::HttpRequest.new(uri).send(method)
      end
    end
  end

  def load_http
    @http_loaded ||= begin
      require 'em-http-request'
      true
    rescue LoadError
      raise LoadError, 'in order to use HTTP requests in EventMachine engine you should add `em-http-request` gem to your Gemfile'
    end
  end

  def send_udp_datagram(message, host, port)
    EM.schedule do
      @udp_socket ||= EM.open_datagram_socket '127.0.0.1', 0
      @udp_socket.send_datagram message, host, port
    end
  end

  def every(interval, fire_immediately: true, on_error: nil, &block)
    EM.schedule do
      block.call if fire_immediately

      EM.add_periodic_timer(interval) do
        begin
          block.call
        rescue => error
          interval_binding = binding
          Array(on_error).each do |handler|
            handler.call error, :interval, interval_binding
          end
        end
      end
    end
  end

  extend self

  Monus::Engine.register :eventmachine, self
end