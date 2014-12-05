class PermessageDeflate
  class Session

    MESSAGE_OPCODES = [1, 2]

    def valid_frame_rsv(frame)
      if MESSAGE_OPCODES.include?(frame.opcode)
        {:rsv1 => true, :rsv2 => false, :rsv3 => false}
      else
        {:rsv1 => false, :rsv2 => false, :rsv3 => false}
      end
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
      inflate = Zlib::Inflate.new(-@peer_window_bits)
      @inflate = inflate if @peer_context_takeover
      inflate
    end

    def get_deflate
      return @deflate if @deflate
      deflate = Zlib::Deflate.new(Zlib::DEFAULT_COMPRESSION, -@own_window_bits)
      @deflate = deflate if @own_context_takeover
      deflate
    end

  end
end
