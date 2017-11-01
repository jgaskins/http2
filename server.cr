require "./src/server"

class EchoHandler
  include HTTP::Server::Handler

  def call(context : HTTP::Server::Context)
    request, response = context.request, context.response

    case request.method
    when "PUT"
      if request.path == "/echo"
        response.headers["server"] = "h2/0.0.0"

        if len = request.content_length
          response.headers["content-length"] = len.to_s
        end
        if type = request.headers["content-type"]?
          response.headers["content-type"] = type
        end

        buffer = Bytes.new(8192)

        loop do
          count = request.body.read(buffer)
          break if count == 0
          response.write(buffer[0, count])
        end

        return
      end
    end

    call_next(context)
  end
end

class NotFoundHandler
  include HTTP::Server::Handler

  def call(context : HTTP::Server::Context)
    response = context.response
    response.status = 404
    response.headers["server"] = "h2/0.0.0"
    response.headers["content-type"] = "text/plain"
    response << "404 NOT FOUND\n"
  end
end

if ENV["TLS"]?
  ssl_context = OpenSSL::SSL::Context::Server.new
  ssl_context.certificate_chain = File.join(__DIR__, "ssl", "server.crt")
  ssl_context.private_key = File.join(__DIR__, "ssl", "server.key")
end

unless ENV["CI"]?
  logger = Logger.new(STDOUT)
  logger.level = Logger::DEBUG
end

host = ENV["HOST"]? || "::"
port = (ENV["PORT"]? || 9292).to_i

handlers = [
  EchoHandler.new,
  NotFoundHandler.new,
]
server = HTTP::Server.new(host, port, ssl_context, logger)

if ssl_context
  puts "listening on https://#{host}:#{port}/"
else
  puts "listening on http://#{host}:#{port}/"
end
server.listen(handlers)
