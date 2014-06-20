class Redis
  class Client
    MINUS    = "-".freeze
    PLUS     = "+".freeze
    COLON    = ":".freeze
    DOLLAR   = "$".freeze
    ASTERISK = "*".freeze

    attr_accessor :db, :host, :port, :password, :logger
    attr :timeout

    def initialize(options = {})
      @host = options[:host] || "127.0.0.1"
      @port = (options[:port] || 6379).to_i
      @db = (options[:db] || 0).to_i
      @timeout = (options[:timeout] || 5).to_i
      @password = options[:password]
      @logger = options[:logger]
      @sock = nil
    end

    def connect
      connect_to(@host, @port)
      call(:auth, @password) if @password
      call(:select, @db) if @db != 0
      @sock
    end

    def id
      "redis://#{host}:#{port}/#{db}"
    end

    def call(*args)
      process(args) do
        read
      end
    end

    def call_loop(*args)
      process(args) do
        loop { yield(read) }
      end
    end

    def call_pipelined(commands)
      process(*commands) do
        Array.new(commands.size) { read }
      end
    end

    def call_without_timeout(*args)
      without_socket_timeout do
        call(*args)
      end
    end

    def process(*commands)
      logging(commands) do
        ensure_connected do
          @sock.write(join_commands(commands))
          yield if block_given?
        end
      end
    end

    def connected?
      !! @sock
    end

    def disconnect
      return unless connected?

      begin
        @sock.close
      rescue
      ensure
        @sock = nil
      end
    end

    def reconnect
      disconnect
      connect
    end

    def read
      # We read the first byte using read() mainly because gets() is
      # immune to raw socket timeouts.
      begin
        reply_type = @sock.read(1)
      rescue Errno::EAGAIN

        # We want to make sure it reconnects on the next command after the
        # timeout. Otherwise the server may reply in the meantime leaving
        # the protocol in a desync status.
        disconnect

        raise Errno::EAGAIN, "Timeout reading from the socket"
      end

      raise Errno::ECONNRESET, "Connection lost" unless reply_type

      format_reply(reply_type, @sock.gets)
    end

    def without_socket_timeout
      ensure_connected do
        begin
          self.timeout = 0
          yield
        ensure
          self.timeout = @timeout if connected?
        end
      end
    end

  protected

    def build_command(name, *args)
      command = []
      command << "*#{args.size + 1}"
      command << "$#{string_size name}"
      command << name

      args.each do |arg|
        arg = arg.to_s
        command << "$#{string_size arg}"
        command << arg
      end

      command
    end

    def deprecated(old, new = nil, trace = caller[0])
      message = "The method #{old} is deprecated and will be removed in 2.0"
      message << " - use #{new} instead" if new
      Redis.deprecate(message, trace)
    end

    COMMAND_DELIMITER = "\r\n"

    def join_commands(commands)
      commands.map do |command|
        build_command(*command).join(COMMAND_DELIMITER) + COMMAND_DELIMITER
      end.join(COMMAND_DELIMITER) + COMMAND_DELIMITER
    end

    if "".respond_to?(:bytesize)
      def string_size(string)
        string.to_s.bytesize
      end
    else
      def string_size(string)
        string.to_s.size
      end
    end

    def format_reply(reply_type, line)
      case reply_type
      when MINUS    then format_error_reply(line)
      when PLUS     then format_status_reply(line)
      when COLON    then format_integer_reply(line)
      when DOLLAR   then format_bulk_reply(line)
      when ASTERISK then format_multi_bulk_reply(line)
      else raise ProtocolError.new(reply_type)
      end
    end

    def format_error_reply(line)
      raise "-" + line.strip
    end

    def format_status_reply(line)
      line.strip
    end

    def format_integer_reply(line)
      line.to_i
    end

    def format_bulk_reply(line)
      bulklen = line.to_i
      return if bulklen == -1
      reply = encode(@sock.read(bulklen))
      @sock.read(2) # Discard CRLF.
      reply
    end

    def format_multi_bulk_reply(line)
      n = line.to_i
      return if n == -1

      Array.new(n) { read }
    end

    def logging(commands)
      return yield unless @logger && @logger.debug?

      begin
        commands.each do |name, *args|
          @logger.debug("Redis >> #{name.to_s.upcase} #{args.join(" ")}")
        end

        t1 = Time.now
        yield
      ensure
        @logger.debug("Redis >> %0.2fms" % ((Time.now - t1) * 1000))
      end
    end

    def connect_to(host, port)
      with_timeout(@timeout) do
        @sock = TCPSocket.new(host, port)
      end

      @sock.setsockopt Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1

      # If the timeout is set we set the low level socket options in order
      # to make sure a blocking read will return after the specified number
      # of seconds. This hack is from memcached ruby client.
      self.timeout = @timeout

    rescue Errno::ECONNREFUSED
      raise Errno::ECONNREFUSED, "Unable to connect to Redis on #{host}:#{port}"
    end

    def timeout=(timeout)
      secs   = Integer(timeout)
      usecs  = Integer((timeout - secs) * 1_000_000)
      optval = [secs, usecs].pack("l_2")

      begin
        @sock.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
        @sock.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval
      rescue Errno::ENOPROTOOPT
      end
    end

    def ensure_connected
      connect unless connected?

      begin
        yield
      rescue Errno::ECONNRESET, Errno::EPIPE, Errno::ECONNABORTED, Errno::EBADF
        if reconnect
          yield
        else
          raise Errno::ECONNRESET
        end
      end
    end

    class ThreadSafe < self
      def initialize(*args)
        require "monitor"

        super(*args)
        @mutex = ::Monitor.new
      end

      def synchronize(&block)
        @mutex.synchronize(&block)
      end

      def ensure_connected(&block)
        synchronize { super }
      end
    end

    begin
      require "system_timer"

      def with_timeout(seconds, &block)
        SystemTimer.timeout_after(seconds, &block)
      end

    rescue LoadError
      warn "WARNING: using the built-in Timeout class which is known to have issues when used for opening connections. Install the SystemTimer gem if you want to make sure the Redis client will not hang." unless RUBY_VERSION >= "1.9" || RUBY_PLATFORM =~ /java/

      require "timeout"

      def with_timeout(seconds, &block)
        Timeout.timeout(seconds, &block)
      end
    end

    if defined?(Encoding)
      def encode(string)
        string.force_encoding(Encoding::default_external)
      end
    else
      def encode(string)
        string
      end
    end
  end
end
