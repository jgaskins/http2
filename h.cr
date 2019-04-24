require "./src/server"

STDOUT.sync = true
STDERR.sync = true

port = ENV.fetch("PORT", "9292").to_i
host = ENV.fetch("HOST", "::")
tls = ENV.fetch("TLS", "false") == "true"

server = HTTP::Server.new(host, port) do |context|
  request, response = context.request, context.response
  authority = request.headers[":authority"]? || request.headers["Host"]?

  if request.method == "PUT" && request.path == "/upload"
    if type = request.headers["content-type"]?
      response.headers["content-type"] = type
    end
    if length = request.headers["content-length"]?
      response.headers["content-length"] = length
    end

    body = request.body.not_nil!
    buffer = Bytes.new(8192)

    loop do
      read_bytes = body.read(buffer)
      break if read_bytes == 0

      sleep 1

      response << buffer[0, read_bytes]
    end
  elsif request.method == "GET" && request.path == "/download"
    filename = "The7thContinent_KSdemo_Francais.pdf"

    response.headers["content-type"] = "application/pdf"
    response.headers["content-disposition"] = "attachment; filename=#{filename}"

    File.open("/home/julien/Téléchargements/#{filename}", "rb") do |file|
      IO.copy(file, response)
    end
  #elsif request.method == "GET" && request.path == "/count"
  #  response.headers["content-type"] = "text/plain"
  #  loop do |i|
  #    response << "#{i}\n"
  #  end
  else
    response.headers["content-type"] = "text/plain"
    response << "Received #{request.method} #{request.path} (#{authority})\n"
    response << "Served with #{request.version}\n"
  end
end

if ENV["CI"]?
  server.logger = Logger::Dummy.new(File.open("/dev/null"))
elsif ENV["DEBUG"]?
  server.logger.level = Logger::Severity::DEBUG
end

if tls
  tls_context = HTTP::Server.default_tls_context
  tls_context.certificate_chain = File.join("ssl", "server.crt")
  tls_context.private_key = File.join("ssl", "server.key")
  server.tls = tls_context
end

puts "Listening on #{host}:#{port} tls=#{tls}"
server.listen
