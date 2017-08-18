class PermessageDeflate
  class ServerSession < Session

    def self.valid_params?(params)
      return false unless super

      if params.has_key?('client_max_window_bits')
        return false unless ([true] + VALID_WINDOW_BITS).include?(params['client_max_window_bits'])
      end

      true
    end

    def initialize(options, params)
      super(options)
      @params = params
    end

    def generate_response
      response = {}

      # https://tools.ietf.org/html/rfc7692#section-7.1.1.1

      @own_context_takeover = !@accept_no_context_takeover &&
                              !@params['server_no_context_takeover']

      response['server_no_context_takeover'] = true unless @own_context_takeover

      # https://tools.ietf.org/html/rfc7692#section-7.1.1.2

      @peer_context_takeover = !@request_no_context_takeover &&
                               !@params['client_no_context_takeover']

      response['client_no_context_takeover'] = true unless @peer_context_takeover

      # https://tools.ietf.org/html/rfc7692#section-7.1.2.1

      @own_window_bits = [ @accept_max_window_bits || MAX_WINDOW_BITS,
                           @params['server_max_window_bits'] || MAX_WINDOW_BITS
                         ].min

      # In violation of the spec, Firefox closes the connection if it does not
      # send server_max_window_bits but the server includes this in its response
      if @own_window_bits < MAX_WINDOW_BITS and @params['server_max_window_bits']
        response['server_max_window_bits'] = @own_window_bits
      end

      # https://tools.ietf.org/html/rfc7692#section-7.1.2.2

      if client_max = @params['client_max_window_bits']
        client_max = MAX_WINDOW_BITS if client_max == true
        @peer_window_bits = [@request_max_window_bits || MAX_WINDOW_BITS, client_max].min
      else
        @peer_window_bits = MAX_WINDOW_BITS
      end

      if @peer_window_bits < MAX_WINDOW_BITS
        response['client_max_window_bits'] = @peer_window_bits
      end

      response
    end

  end
end
