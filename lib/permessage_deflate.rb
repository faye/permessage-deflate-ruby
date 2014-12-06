require 'zlib'

class PermessageDeflate
  root = File.expand_path('..', __FILE__)
  require root + '/permessage_deflate/session'
  require root + '/permessage_deflate/client_session'
  require root + '/permessage_deflate/server_session'

  module Extension
    define_method(:name) { 'permessage-deflate' }
    define_method(:type) { 'permessage' }
    define_method(:rsv1) { true  }
    define_method(:rsv2) { false }
    define_method(:rsv3) { false }

    def create_client_session
      ClientSession.new
    end

    def create_server_session(offers)
      offers.each do |offer|
        return ServerSession.new(offer) if ServerSession.valid_params?(offer)
      end
    end
  end

  extend Extension
end
