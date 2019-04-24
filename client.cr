require "socket"
require "openssl"
require "./src/connection"

module HTTP2
  class Client
    @connection : Connection
    @requests = {} of Stream => Channel::Unbuffered(Nil)

    alias ServerPushHandler = (HTTP::Headers, IO) -> Bool?
    @server_push_handler : ServerPushHandler?

    def initialize(host : String, port : Int32, ssl_context, logger = nil, server_push = false)
      @authority = "#{host}:#{port}"

      io = TCPSocket.new(host, port)

      case ssl_context
      when true
        ssl_context = OpenSSL::SSL::Context::Client.new
        ssl_context.alpn_protocol = "h2"
        io = OpenSSL::SSL::Socket::Client.new(io, ssl_context)
        @scheme = "https"
      when OpenSSL::SSL::Context::Client
        ssl_context.alpn_protocol = "h2"
        io = OpenSSL::SSL::Socket::Client.new(io, ssl_context)
        @scheme = "https"
      else
        @scheme = "http"
      end

      connection = Connection.new(io, Connection::Type::CLIENT, logger || Logger::Dummy.new)
      connection.local_settings.enable_push = server_push
      connection.write_client_preface
      connection.write_settings

      frame = connection.receive
      unless frame.try(&.type) == Frame::Type::SETTINGS
        raise Error.protocol_error("Expected SETTINGS frame")
      end

      @connection = connection
      spawn handle_connection
    end

    private def handle_connection
      loop do
        unless frame = @connection.receive
          next
        end
        case frame.type
        when Frame::Type::HEADERS
          @requests[frame.stream].send(nil)
        when Frame::Type::PUSH_PROMISE
          on_push_promise(frame.stream)
        when Frame::Type::GOAWAY
          break
        end
      end
    end

    private def on_push_promise(stream : Stream)
      if handler = @server_push_handler
        spawn do
          if handler.not_nil!.call(stream.headers, stream.data) == false
            stream.send_rst_stream(Error::Code::NO_ERROR)
          end
        end
      else
        stream.send_rst_stream(Error::Code::NO_ERROR)
      end
    end

    def on_server_push(&handler : ServerPushHandler)
      @server_push_handler = handler
    end

    # TODO: send/stream request body
    def request(headers : HTTP::Headers)
      headers[":authority"] = @authority
      headers[":scheme"] ||= @scheme

      # create stream + wait channel
      stream = @connection.streams.create
      @requests[stream] = Channel::Unbuffered(Nil).new

      # send request
      # stream.send_headers(headers, flags: Frame::Flags::END_STREAM)
      stream.send_headers(headers)

      # wait for response...
      @requests[stream].receive

      if stream.state.open?
        body = stream.data
      end
      yield stream.headers, body

      # eventually close stream
      if stream.active?
        stream.send_rst_stream(Error::Code::NO_ERROR)
      end
      stream.data.skip_to_end
      stream.data.close_read
    end

    def close
      @connection.close unless closed?
    end

    def closed?
      @connection.closed?
    end
  end
end

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

options = {
  ssl_context: !!ENV["TLS"]?,
  logger: logger,
  server_push: true,
}
client = HTTP2::Client.new("localhost", 9292, **options)

client.on_server_push do |handler|
  false
end

NN = (ENV["N"]? || 10).to_i

channel = Channel(Nil).new(NN)

NN.times do |i|
  spawn do
    headers = HTTP::Headers{
      ":method" => "GET",
      ":path" => "/",
      "user-agent" => "crystal h2/0.0.0"
    }

    client.request(headers) do |headers, body|
      puts "REQ ##{i}: #{headers.inspect}"

      # FIXME: body.gets HANGs forever!
      while line = body.try(&.gets)
        puts "REQ ##{i}: #{line}"
      end

      puts "REQ ##{i}: DONE"
      channel.send(nil)
    end
  end
end

NN.times { channel.receive }

client.close
