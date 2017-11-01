require "./request"
require "./response"

module HTTP
  class Server
    class Context
      getter request : Request
      getter response : Response

      # :nodoc:
      protected def initialize(@request, @response)
      end
    end
  end
end
