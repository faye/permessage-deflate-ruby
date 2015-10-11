class PermessageDeflate
  class ClientSession < Session

    def self.valid_params?(params)
      return false unless super

      if params.has_key?('client_max_window_bits')
        return false unless VALID_WINDOW_BITS.include?(params['client_max_window_bits'])
      end

      true
    end

    def generate_offer
      offer = {}

      if @accept_no_context_takeover
        offer['client_no_context_takeover'] = true
      end

      if @accept_max_window_bits
        unless VALID_WINDOW_BITS.include?(@accept_max_window_bits)
          raise ConfigurationError, 'Invalid value for max_window_bits'
        end
        offer['client_max_window_bits'] = @accept_max_window_bits
      else
        offer['client_max_window_bits'] = true
      end

      if @request_no_context_takeover
        offer['server_no_context_takeover'] = true
      end

      if @request_max_window_bits
        unless VALID_WINDOW_BITS.include?(@request_max_window_bits)
          raise ConfigurationError, 'Invalid value for request_max_window_bits'
        end
        offer['server_max_window_bits'] = @request_max_window_bits
      end

      offer
    end

    def activate(params)
      return false unless ClientSession.valid_params?(params)

      if @accept_max_window_bits and params['client_max_window_bits']
        return false if params['client_max_window_bits'] > @accept_max_window_bits
      end

      if @request_no_context_takeover and !params['server_no_context_takeover']
        return false
      end

      if @request_max_window_bits
        return false unless params['server_max_window_bits']
        return false if params['server_max_window_bits'] > @request_max_window_bits
      end

      @own_context_takeover = !(@accept_no_context_takeover || params['client_no_context_takeover'])
      @own_window_bits = [
        @accept_max_window_bits || MAX_WINDOW_BITS,
        params['client_max_window_bits'] || MAX_WINDOW_BITS
      ].min

      @peer_context_takeover = !params['server_no_context_takeover']
      @peer_window_bits = params['server_max_window_bits'] || MAX_WINDOW_BITS

      true
    end

  end
end
