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
      [{'client_max_window_bits' => true}]
    end

    def activate(params)
      return false unless ClientSession.valid_params?(params)

      @own_context_takeover = !params['client_no_context_takeover']
      @own_window_bits = params['client_max_window_bits'] || DEFAULT_MAX_WINDOW_BITS

      @peer_context_takeover = !params['server_no_context_takeover']
      @peer_window_bits = params['server_max_window_bits'] || DEFAULT_MAX_WINDOW_BITS

      true
    end

  end
end
