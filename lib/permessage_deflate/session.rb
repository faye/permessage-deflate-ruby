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
      compressed = message.frames.first.rsv1
      return message unless compressed

      inflate = get_inflate

      message.data = inflate.inflate(message.data) +
                     inflate.inflate([0x00, 0x00, 0xff, 0xff].pack('C*'))

      inflate.close unless @inflate
      message
    end

    def process_outgoing_message(message)
      deflate = get_deflate
      payload = (deflate.deflate(message.data) + deflate.flush)[0...-4]
      frame   = message.frames.first

      deflate.close unless @deflate

      frame.final   = true
      frame.rsv1    = true
      frame.length  = payload.bytesize
      frame.payload = payload

      message.data   = payload
      message.frames = [frame]

      message
    end

    def close
      @inflate.close if @inflate
      @inflate = nil

      @deflate.close if @deflate
      @deflate = nil
    end

  private

    def f(string)
      bytes = string.bytes.map { |b| b.to_s(16).rjust(2, '0') }
      "<#{string.encoding}: #{bytes * ' '}>"
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
