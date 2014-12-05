require 'zlib'

class PermessageDeflate
  VALID_PARAMS = [
    'server_no_context_takeover',
    'client_no_context_takeover',
    'server_max_window_bits',
    'client_max_window_bits'
  ]

  DEFAULT_MAX_WINDOW_BITS = 15
  VALID_WINDOW_BITS = [8, 9, 10, 11, 12, 13, 14, 15]

  root = File.expand_path('..', __FILE__)
  require root + '/permessage_deflate/session'
  require root + '/permessage_deflate/server_session'

  module Extension
    define_method(:name) { 'permessage-deflate' }
    define_method(:type) { 'permessage' }
    define_method(:rsv1) { true  }
    define_method(:rsv2) { false }
    define_method(:rsv3) { false }

    def create_server_session(offers)
      offers.each do |offer|
        return ServerSession.new(offer) if ServerSession.valid_params?(offer)
      end
    end
  end

  extend Extension
end
