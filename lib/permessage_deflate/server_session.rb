class PermessageDeflate
  class ServerSession < Session

    def self.valid_params?(params)
      return false unless super

      if params.has_key?('client_max_window_bits')
        return false unless ([true] + VALID_WINDOW_BITS).include?(params['client_max_window_bits'])
      end

      true
    end

    def initialize(params)
      super()
      @params = params
    end

    def generate_response
      params = {}

      # https://tools.ietf.org/html/draft-ietf-hybi-permessage-compression#section-8.1.1.1
      if @params['server_no_context_takeover']
        params['server_no_context_takeover'] = true
      end

      # https://tools.ietf.org/html/draft-ietf-hybi-permessage-compression#section-8.1.1.2
      if @params['client_no_context_takeover']
        params['client_no_context_takeover'] = true
      end

      # https://tools.ietf.org/html/draft-ietf-hybi-permessage-compression#section-8.1.2.1
      if server_max = @params['server_max_window_bits']
        params['server_max_window_bits'] = [server_max, DEFAULT_MAX_WINDOW_BITS].min
      end

      # https://tools.ietf.org/html/draft-ietf-hybi-permessage-compression#section-8.1.2.2
      if client_max = @params['client_max_window_bits']
        client_max = DEFAULT_MAX_WINDOW_BITS if client_max == true
        params['client_max_window_bits'] = [client_max, DEFAULT_MAX_WINDOW_BITS].min
      end

      @own_context_takeover = !params['server_no_context_takeover']
      @own_window_bits = params['server_max_window_bits'] || DEFAULT_MAX_WINDOW_BITS

      @peer_context_takeover = !params['client_no_context_takeover']
      @peer_window_bits = params['client_max_window_bits'] || DEFAULT_MAX_WINDOW_BITS

      params
    end

  end
end
