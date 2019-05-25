require 'resolv'

module Monus::Engine::EventMachine
  def prepare
    @dns_cache = {}
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

      ip = @dns_cache[host]

      if ip.nil? and (host =~ Resolv::IPv4::Regex or host =~ Resolv::IPv6::Regex)
        ip = host
        @dns_cache[host] = ip
      end

      if ip
        @udp_socket.send_datagram message, ip, port
      else
        EM::DNS::Resolver.resolve(host).callback do |ip_list|
          ip = ip_list.first
          @dns_cache[host] = ip
          send_udp_datagram(message, host, port)
        end
      end
    end
  end

  def invalidate_dns_cache!
    keys = @dns_cache.keys.reject { |key| key =~ Resolv::IPv4::Regex || key =~ Resolv::IPv6::Regex }
    keys.each { |key| @dns_cache.delete(key) }
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