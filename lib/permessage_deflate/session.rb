class PermessageDeflate
  class Session

    VALID_PARAMS = [
      'server_no_context_takeover',
      'client_no_context_takeover',
      'server_max_window_bits',
      'client_max_window_bits'
    ]

    MIN_WINDOW_BITS   = 9
    MAX_WINDOW_BITS   = 15
    VALID_WINDOW_BITS = [8, 9, 10, 11, 12, 13, 14, 15]

    def self.valid_params?(params)
      return false unless params.keys.all? { |k| VALID_PARAMS.include?(k) }
      return false if params.values.grep(Array).any?

      if params.has_key?('server_no_context_takeover')
        return false unless params['server_no_context_takeover'] == true
      end

      if params.has_key?('client_no_context_takeover')
        return false unless params['client_no_context_takeover'] == true
      end

      if params.has_key?('server_max_window_bits')
        return false unless VALID_WINDOW_BITS.include?(params['server_max_window_bits'])
      end

      true
    end

    def initialize(options)
      @level     = options.fetch(:level,     Zlib::DEFAULT_COMPRESSION)
      @mem_level = options.fetch(:mem_level, Zlib::DEF_MEM_LEVEL)
      @strategy  = options.fetch(:strategy,  Zlib::DEFAULT_STRATEGY)

      @accept_no_context_takeover  = options.fetch(:no_context_takeover, false)
      @accept_max_window_bits      = options.fetch(:max_window_bits, nil)
      @request_no_context_takeover = options.fetch(:request_no_context_takeover, false)
      @request_max_window_bits     = options.fetch(:request_max_window_bits, nil)

      @deflate = @inflate = nil
    end

    def process_incoming_message(message)
      return message unless message.rsv1

      inflate = get_inflate

      message.data = inflate.inflate(message.data) +
                     inflate.inflate([0x00, 0x00, 0xff, 0xff].pack('C*'))

      free(inflate) unless @inflate
      message
    end

    def process_outgoing_message(message)
      deflate = get_deflate

      message.data = deflate.deflate(message.data, Zlib::SYNC_FLUSH)[0...-4]
      message.rsv1 = true

      free(deflate) unless @deflate
      message
    end

    def close
      free(@inflate)
      @inflate = nil

      free(@deflate)
      @deflate = nil
    end

  private

    def free(codec)
      return if codec.nil?
      codec.finish rescue nil
      codec.close
    end

    def get_inflate
      return @inflate if @inflate

      window_bits = [@peer_window_bits, MIN_WINDOW_BITS].max
      inflate     = Zlib::Inflate.new(-window_bits)

      @inflate = inflate if @peer_context_takeover
      inflate
    end

    def get_deflate
      return @deflate if @deflate

      window_bits = [@own_window_bits, MIN_WINDOW_BITS].max
      deflate     = Zlib::Deflate.new(@level, -window_bits, @mem_level, @strategy)

      @deflate = deflate if @own_context_takeover
      deflate
    end

  end
end
