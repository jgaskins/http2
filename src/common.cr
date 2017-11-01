require "gzip"
require "zlib"

module HTTP
  # :nodoc:
  def self.parse_content_type_header(header : String?)
    return {nil, nil} unless header

    index = 0
    content_type = charset = nil

    header.split(';') do |part|
      if index == 0
        content_type = part.strip
      else
        if a = part.index('=')
          if part[0...a].ends_with?("charset")
            charset = part[(a + 1)..-1].strip
            break
          end
        end
      end
      index += 1
    end

    {content_type, charset}
  end

  # :nodoc:
  def self.decode_body(body : IO?, headers : HTTP::Headers)
    return unless body

    case headers["Content-Encoding"]?
    when "gzip"
      body = Gzip::Reader.new(body, sync_close: true)
    when "deflate"
      body = Zlib::Reader.new(body, sync_close: true)
    end

    _, charset = HTTP.parse_content_type_header(headers["Content-Type"]?)
    body.set_encoding(charset, invalid: :skip) if charset

    body
  end
end
