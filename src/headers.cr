module HTTP
  # List of HTTP headers.
  #
  # In HTTP/1 header names were case insensitive; conventions used the
  # Camel-Cased form (e.g. `Content-Type`). HTTP/2 settled to all lower-cased
  # (e.g. `content-type`). This structure allows to access and set headers in a
  # case_insensitive way to accomadate both versions, thought the lower-cased
  # form should be preferred.
  #
  # Header names may appear multiple times with different values. For example
  # cookies must each be declared with a distinct `set-cookie` header. This
  # structure thus allows to access headers concatenated to a single string
  # (each value separated by commas) with `#[]` or `#[]?` and access all values
  # as an array with `#get` or `#get?` instead.
  struct Headers
    include Enumerable({String, Array(String)})

    # :nodoc:
    struct Key
      # TODO: consider always normalizing headers to the lower-cased form

      protected getter name : String

      def initialize(@name)
      end

      def ==(other : String)
        return false unless @name.bytesize == other.bytesize

        a = @name.to_unsafe
        b = other.to_unsafe

        @name.bytesize.times do |i|
          unless a[i] == b[i] || normalize_byte(a[i]) == normalize_byte(b[i])
            return false
          end
        end

        true
      end

      def ==(other : Key)
        self == other.name
      end

      def hash(hasher)
        @name.each_byte { |byte| hasher = normalize_byte(byte).hash(hasher) }
        hasher
      end

      private def normalize_byte(byte)
        if byte.unsafe_chr.ascii_uppercase?
          byte + 32
        else
          byte
        end
      end
    end

    protected getter headers : Hash(Key, Array(String))

    def self.new
      headers = {} of Key => Array(String)
      new(headers)
    end

    # :nodoc:
    protected def initialize(@headers)
    end

    def [](name : String) : String
      self[name]? || raise KeyError.new
    end

    def []?(name : String) : String?
      key = Key.new(name)
      if values = @headers[key]?
        concat(values)
      end
    end

    def []=(name : String, value : String)
      key = Key.new(name)
      if values = @headers[key]?
        values.clear
        values << value
      else
        @headers[key] = [value]
      end
      value
    end

    def []=(name : String, values : Array(String))
      key = Key.new(name)
      @headers[key] = values
    end

    def add(name : String, value : String) : Nil
      key = Key.new(name)
      if values = @headers[key]?
        values << value
      else
        @headers[key] = [value]
      end
    end

    def add(name : String, values : Array(String)) : Nil
      key = Key.new(name)
      if current = @headers[key]?
        current.concat(values)
      else
        @headers[key] = values
      end
    end

    def clear
      @headers.clear
    end

    def clone
      Headers.new(@headers.clone)
    end

    def dup
      clone
    end

    def delete(name : String)
      key = Key.new(name)
      if values = @headers.delete(key)
        concat(values)
      end
    end

    def each
      @headers.each do |key, value|
        yield({key.name, value})
      end
    end

    def empty?
      @headers.empty?
    end

    def ==(other : Headers)
      return false unless size == other.size
      @headers.each do |key, values|
        return false unless other_values = other.headers[key]?
        return false unless other_values.size == values.size
        return false unless values.all? { |value| other_values.includes?(value) }
      end
      true
    end

    def get(name : String)
      @headers[Key.new(name)]
    end

    def get?(name : String)
      @headers[Key.new(name)]?
    end

    def has_key?(name : String)
      @headers.has_key?(Key.new(name))
    end

    def inspect(io : IO)
      io << "HTTP::Headers{"
      @headers.each_with_index do |(key, values), index|
        io << ", " if index > 0
        key.name.inspect(io)
        io << " => "
        if values.size == 1
          values.first.inspect(io)
        else
          values.inspect(io)
        end
      end
      io << "}"
    end

    def merge!(other : Headers)
      other.headers.each { |(key, name)| @headers[key] = name }
      self
    end

    def pretty_print(pp)
      pp.list("HTTP::Headers{", @headers.keys.sort_by(&.name), "}") do |key|
        pp.group do
          key.name.pretty_print(pp)
          pp.text " =>"
          pp.nest do
            pp.breakable
            values = @headers[key]
            if values.size == 1
              values.first.pretty_print(pp)
            else
              values.pretty_print(pp)
            end
          end
        end
      end
    end

    def same?(other : Headers)
      headers.object_id == other.headers.object_id
    end

    def size
      @headers.size
    end

    def to_s(io : IO)
      inspect(io)
    end

    private def concat(values)
      case values.size
      when 0
        ""
      when 1
        values.first
      else
        values.join(", ")
      end
    end
  end
end
