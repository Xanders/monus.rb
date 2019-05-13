module Monus::Backend::InfluxDB
  def prepare
    @host = Monus.options.dig(:influxdb_options, :host) || 'localhost'

    @measurement = Monus.options.dig(:influxdb_options, :measurement)
    unless @measurement
      raise Monus::ConfigurationError, 'when using InfluxDB backend you should provide `influxdb_options/measurement` configuration with measurement (table) name'
    end

    @mode = Monus.options.dig(:influxdb_options, :mode)
    case @mode
    when :udp
      @udp_port = Monus.options.dig(:influxdb_options, :udp_port)
      unless @udp_port
        raise Monus::ConfigurationError, 'when using UDP mode you should provide `influxdb_options/udp_port` configuration with corresponding port number'
      end
    when :http
      @http_port = Monus.options.dig(:influxdb_options, :http_port)
      unless @http_port
        raise Monus::ConfigurationError, 'when using HTTP mode you should provide `influxdb_options/http_port` configuration with corresponding port number'
      end

      @database = Monus.options.dig(:influxdb_options, :database)
      unless @database
        raise Monus::ConfigurationError, 'when using HTTP mode you should provide `influxdb_options/database` configuration with database name'
      end

      @http_connection = Monus.engine.make_http_connection @host, @http_port

      @uri = "/write?db=#{@database}"
    else
      raise Monus::ConfigurationError, 'when using InfluxDB backend you should provide `influxdb_options/mode` configuration with `:udp` or `:http` value'
    end

    @global_tags = Monus.options.dig(:influxdb_options, :global_tags)&.map { |key, value| ",#{key}=#{value}" }&.join
  end

  def write(fields, tags = nil)
    fields = fields.map { |key, value| "#{key}=#{value.inspect}" }.join(',')

    tags = tags&.map { |key, value| ",#{key}=#{value}" }&.join

    message = "#{@measurement}#{@global_tags}#{tags} #{fields}"

    case @mode
    when :udp
      Monus.engine.send_udp_datagram message, @host, @udp_port
    when :http
      Monus.engine.send_http_request @uri, method: :post, body: message, connection: @http_connection
    end
  end

  extend self

  Monus::Backend.register :influxdb, self
end