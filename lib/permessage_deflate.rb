require 'zlib'

class PermessageDeflate
  root = File.expand_path('..', __FILE__)
  require root + '/permessage_deflate/session'
  require root + '/permessage_deflate/client_session'
  require root + '/permessage_deflate/server_session'

  ConfigurationError = Class.new(ArgumentError)

  VALID_OPTIONS = [
    :level,
    :mem_level,
    :strategy,
    :no_context_takeover,
    :max_window_bits,
    :request_no_context_takeover,
    :request_max_window_bits
  ]

  def self.validate_options(options, valid_keys)
    options.keys.each do |key|
      unless valid_keys.include?(key)
        raise ConfigurationError, "Unrecognized option: #{key.inspect}"
      end
    end
  end

  module Extension
    define_method(:name) { 'permessage-deflate' }
    define_method(:type) { 'permessage' }
    define_method(:rsv1) { true  }
    define_method(:rsv2) { false }
    define_method(:rsv3) { false }

    def configure(options)
      @options ||= nil

      PermessageDeflate.validate_options(options, VALID_OPTIONS)
      options = (@options || {}).merge(options)
      PermessageDeflate.new(options)
    end

    def create_client_session
      ClientSession.new(@options || {})
    end

    def create_server_session(offers)
      offers.each do |offer|
        return ServerSession.new(@options || {}, offer) if ServerSession.valid_params?(offer)
      end
      nil
    end
  end

  include Extension
  extend  Extension

  def initialize(options)
    @options = options
  end
end
