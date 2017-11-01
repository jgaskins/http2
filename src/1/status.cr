module HTTP1
  # Returns the default status message of the given HTTP status code.
  #
  # Based on [Hypertext Transfer Protocol (HTTP) Status Code Registry](https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml)
  #
  # Last Updated 2017-04-14
  #
  # HTTP Status Codes (source: [http-status-codes-1.csv](https://www.iana.org/assignments/http-status-codes/http-status-codes-1.csv))
  #
  # * 1xx: Informational - Request received, continuing process
  # * 2xx: Success - The action was successfully received, understood, and accepted
  # * 3xx: Redirection - Further action must be taken in order to complete the request
  # * 4xx: Client Error - The request contains bad syntax or cannot be fulfilled
  # * 5xx: Server Error - The server failed to fulfill an apparently valid request
  def self.default_status_message_for(status : Int32) : String
    case status
    when 100 then "Continue"
    when 101 then "Switching Protocols"
    when 102 then "Processing"
    when 200 then "OK"
    when 201 then "Created"
    when 202 then "Accepted"
    when 203 then "Non-Authoritative Information"
    when 204 then "No Content"
    when 205 then "Reset Content"
    when 206 then "Partial Content"
    when 207 then "Multi-Status"
    when 208 then "Already Reported"
    when 226 then "IM Used"
    when 300 then "Multiple Choices"
    when 301 then "Moved Permanently"
    when 302 then "Found"
    when 303 then "See Other"
    when 304 then "Not Modified"
    when 305 then "Use Proxy"
    when 307 then "Temporary Redirect"
    when 308 then "Permanent Redirect"
    when 400 then "Bad Request"
    when 401 then "Unauthorized"
    when 402 then "Payment Required"
    when 403 then "Forbidden"
    when 404 then "Not Found"
    when 405 then "Method Not Allowed"
    when 406 then "Not Acceptable"
    when 407 then "Proxy Authentication Required"
    when 408 then "Request Timeout"
    when 409 then "Conflict"
    when 410 then "Gone"
    when 411 then "Length Required"
    when 412 then "Precondition Failed"
    when 413 then "Payload Too Large"
    when 414 then "URI Too Long"
    when 415 then "Unsupported Media Type"
    when 416 then "Range Not Satisfiable"
    when 417 then "Expectation Failed"
    when 421 then "Misdirected Request"
    when 422 then "Unprocessable Entity"
    when 423 then "Locked"
    when 424 then "Failed Dependency"
    when 426 then "Upgrade Required"
    when 428 then "Precondition Required"
    when 429 then "Too Many Requests"
    when 431 then "Request Header Fields Too Large"
    when 451 then "Unavailable For Legal Reasons"
    when 500 then "Internal Server Error"
    when 501 then "Not Implemented"
    when 502 then "Bad Gateway"
    when 503 then "Service Unavailable"
    when 504 then "Gateway Timeout"
    when 505 then "HTTP Version Not Supported"
    when 506 then "Variant Also Negotiates"
    when 507 then "Insufficient Storage"
    when 508 then "Loop Detected"
    when 510 then "Not Extended"
    when 511 then "Network Authentication Required"
    else          ""
    end
  end
end
