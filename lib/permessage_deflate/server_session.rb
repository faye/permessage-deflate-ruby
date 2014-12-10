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
      params = {}

      # https://tools.ietf.org/html/draft-ietf-hybi-permessage-compression#section-8.1.1.1
      if @accept_no_context_takeover or @params['server_no_context_takeover']
        params['server_no_context_takeover'] = true
      end

      # https://tools.ietf.org/html/draft-ietf-hybi-permessage-compression#section-8.1.1.2
      if @request_no_context_takeover or @params['client_no_context_takeover']
        params['client_no_context_takeover'] = true
      end

      # https://tools.ietf.org/html/draft-ietf-hybi-permessage-compression#section-8.1.2.1
      if @accept_max_window_bits or @params['server_max_window_bits']
        accept_max = @accept_max_window_bits || DEFAULT_MAX_WINDOW_BITS
        server_max = @params['server_max_window_bits'] || DEFAULT_MAX_WINDOW_BITS
        params['server_max_window_bits'] = [accept_max, server_max].min
      end

      # https://tools.ietf.org/html/draft-ietf-hybi-permessage-compression#section-8.1.2.2
      if client_max = @params['client_max_window_bits']
        if client_max == true
          params['client_max_window_bits'] = @request_max_window_bits if @request_max_window_bits
        else
          request_max = @request_max_window_bits || DEFAULT_MAX_WINDOW_BITS
          params['client_max_window_bits'] = [request_max, client_max].min
        end
      end

      @own_context_takeover = !params['server_no_context_takeover']
      @own_window_bits = params['server_max_window_bits'] || DEFAULT_MAX_WINDOW_BITS

      @peer_context_takeover = !params['client_no_context_takeover']
      @peer_window_bits = params['client_max_window_bits'] || DEFAULT_MAX_WINDOW_BITS

      params
    end

  end
end
