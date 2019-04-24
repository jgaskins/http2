require "./output"

module HTTP
  class Server
    class Response < IO
      getter headers : HTTP::Headers
      property output : IO

      protected def self.new(connection : HTTP1::Connection) : Response
        headers = HTTP::Headers{":status" => "200"}
        output = LegacyOutput.new(connection, headers)
        new(output, headers)
      end

      protected def self.new(stream : HTTP2::Stream) : Response
        headers = HTTP::Headers{":status" => "200"}
        output = StreamOutput.new(stream, headers)
        new(output, headers)
      end

      private def initialize(output : Output, @headers)
        @output = output.as(IO)
      end

      def status
        @headers[":status"].to_i
      end

      def status=(code : Int32)
        @headers[":status"] = code.to_s
      end

      def upgrade(protocol : String)
        @output.upgrade(protocol) { |io| yield io }
      end

      def upgraded?
        !!@headers["upgrade"]?
      end

      def read(bytes : Bytes)
        raise "can't read from HTTP::Server::Response"
      end

      def write(bytes : Bytes)
        @output.write(bytes)
      end

      def flush
        @output.flush
      end

      def close
        @output.close
      end
    end
  end
end
