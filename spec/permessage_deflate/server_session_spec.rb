require "spec_helper"

describe PermessageDeflate::ServerSession do
  let(:ext)       { PermessageDeflate.configure(options) }
  let(:offer)     { {} }
  let(:session)   { ext.create_server_session([offer]) }
  let(:options)   { {} }
  let(:response)  { session.generate_response }

  let(:deflate)   { double(:deflate, :deflate => "") }
  let(:inflate)   { double(:inflate, :inflate => "") }
  let(:level)     { Zlib::DEFAULT_COMPRESSION }
  let(:mem_level) { Zlib::DEF_MEM_LEVEL }
  let(:strategy)  { Zlib::DEFAULT_STRATEGY }

  let(:message)   { Message.new("hello", true) }

  def process_incoming_message
    session.process_incoming_message(message)
  end

  def process_outgoing_message
    session.process_outgoing_message(message)
  end

  describe "with default options" do
    describe "with an empty offer" do
      it "generates an empty response" do
        expect(response).to eq({})
      end

      it "uses context takeover and 15 window bits for inflating incoming messages" do
        response
        expect(Zlib::Inflate).to receive(:new).with(-15).exactly(1).and_return(inflate)
        process_incoming_message
        process_incoming_message
      end

      it "uses context takeover and 15 window bits for deflating outgoing messages" do
        response
        expect(Zlib::Deflate).to receive(:new).with(level, -15, mem_level, strategy).exactly(1).and_return(deflate)
        process_outgoing_message
        process_outgoing_message
      end
    end

    describe "when the offer includes server_no_context_takeover" do
      before { offer["server_no_context_takeover"] = true }

      it "includes server_no_context_takeover in the response" do
        expect(response).to eq("server_no_context_takeover" => true)
      end

      it "uses no context takeover and 15 window bits for deflating outgoing messages" do
        response
        expect(Zlib::Deflate).to receive(:new).with(level, -15, mem_level, strategy).exactly(2).and_return(deflate)
        expect(deflate).to receive(:finish).exactly(2)
        expect(deflate).to receive(:close).exactly(2)
        process_outgoing_message
        process_outgoing_message
      end
    end

    describe "when the offer includes client_no_context_takeover" do
      before { offer["client_no_context_takeover"] = true }

      it "includes client_no_context_takeover in the response" do
        expect(response).to eq("client_no_context_takeover" => true)
      end

      it "uses no context takeover and 15 window bits for inflating incoming messages" do
        response
        expect(Zlib::Inflate).to receive(:new).with(-15).exactly(2).and_return(inflate)
        expect(inflate).to receive(:finish).exactly(2)
        expect(inflate).to receive(:close).exactly(2)
        process_incoming_message
        process_incoming_message
      end
    end

    describe "when the offer includes server_max_window_bits" do
      before { offer["server_max_window_bits"] = 13 }

      it "includes server_max_window_bits in the response" do
        expect(response).to eq("server_max_window_bits" => 13)
      end

      it "uses context takeover with 13 window bits to deflate outgoing messages" do
        response
        expect(Zlib::Deflate).to receive(:new).with(level, -13, mem_level, strategy).exactly(1).and_return(deflate)
        process_outgoing_message
        process_outgoing_message
      end
    end

    describe "when the offer includes invalid server_max_window_bits" do
      before { offer["server_max_window_bits"] = 20 }

      it "does not create a session" do
        expect(session).to be_nil
      end
    end

    describe "when the offer includes client_max_window_bits" do
      before { offer["client_max_window_bits"] = true }

      it "does not include a client_max_window_bits hint in the response" do
        expect(response).to eq({})
      end

      it "uses context takeover and 15 window bits to inflate incoming messages" do
        response
        expect(Zlib::Inflate).to receive(:new).with(-15).exactly(1).and_return(inflate)
        process_incoming_message
        process_incoming_message
      end
    end

    describe "when the offer includes a client_max_window_bits hint" do
      before { offer["client_max_window_bits"] = 13 }

      it "includes a client_max_window_bits hint in the response" do
        expect(response).to eq("client_max_window_bits" => 13)
      end

      it "uses context takeover and 13 window bits to inflate incoming messages" do
        response
        expect(Zlib::Inflate).to receive(:new).with(-13).exactly(1).and_return(inflate)
        process_incoming_message
        process_incoming_message
      end
    end

    describe "when the offer includes invalid client_max_window_bits" do
      before { offer["client_max_window_bits"] = 20 }

      it "does not create a session" do
        expect(session).to be_nil
      end
    end
  end

  describe "with no_context_takeover" do
    before { options[:no_context_takeover] = true }

    describe "with an empty offer" do
      it "includes server_no_context_takeover in the response" do
        expect(response).to eq("server_no_context_takeover" => true)
      end

      it "uses no context takeover and 15 window bits for deflating outgoing messages" do
        response
        expect(Zlib::Deflate).to receive(:new).with(level, -15, mem_level, strategy).exactly(2).and_return(deflate)
        expect(deflate).to receive(:finish).exactly(2)
        expect(deflate).to receive(:close).exactly(2)
        process_outgoing_message
        process_outgoing_message
      end
    end
  end

  describe "with max_window_bits" do
    before { options[:max_window_bits] = 12 }

    describe "with an empty offer" do
      it "includes server_max_window_bits in the response" do
        expect(response).to eq("server_max_window_bits" => 12)
      end

      it "uses context takeover and 12 window bits for deflating outgoing messages" do
        response
        expect(Zlib::Deflate).to receive(:new).with(level, -12, mem_level, strategy).exactly(1).and_return(deflate)
        process_outgoing_message
        process_outgoing_message
      end
    end

    describe "when the offer has higher server_max_window_bits" do
      before { offer["server_max_window_bits"] = 13 }

      it "includes server_max_window_bits in the response" do
        expect(response).to eq("server_max_window_bits" => 12)
      end

      it "uses context takeover and 12 window bits for deflating outgoing messages" do
        response
        expect(Zlib::Deflate).to receive(:new).with(level, -12, mem_level, strategy).exactly(1).and_return(deflate)
        process_outgoing_message
        process_outgoing_message
      end
    end

    describe "when the offer has lower server_max_window_bits" do
      before { offer["server_max_window_bits"] = 11 }

      it "includes server_max_window_bits in the response" do
        expect(response).to eq("server_max_window_bits" => 11)
      end

      it "uses context takeover and 11 window bits for deflating outgoing messages" do
        response
        expect(Zlib::Deflate).to receive(:new).with(level, -11, mem_level, strategy).exactly(1).and_return(deflate)
        process_outgoing_message
        process_outgoing_message
      end
    end
  end

  describe "with request_no_context_takeover" do
    before { options[:request_no_context_takeover] = true }

    describe "with an empty offer" do
      it "includes client_no_context_takeover in the response" do
        expect(response).to eq("client_no_context_takeover" => true)
      end

      it "uses no context takeover and 15 window bits for inflating incoming messages" do
        response
        expect(Zlib::Inflate).to receive(:new).with(-15).exactly(2).and_return(inflate)
        expect(inflate).to receive(:finish).exactly(2)
        expect(inflate).to receive(:close).exactly(2)
        process_incoming_message
        process_incoming_message
      end
    end
  end

  describe "with request_max_window_bits" do
    before { options[:request_max_window_bits] = 11 }

    describe "with an empty offer" do
      it "does not include client_max_window_bits in the response" do
        expect(response).to eq({})
      end

      it "uses context takeover and 15 window bits for inflating incoming messages" do
        response
        expect(Zlib::Inflate).to receive(:new).with(-15).exactly(1).and_return(inflate)
        process_incoming_message
        process_incoming_message
      end
    end

    describe "when the offer includes client_max_window_bits" do
      before { offer["client_max_window_bits"] = true }

      it "includes client_max_window_bits in the response" do
        expect(response).to eq("client_max_window_bits" => 11)
      end

      it "uses context takeover and 11 window bits for inflating incoming messages" do
        response
        expect(Zlib::Inflate).to receive(:new).with(-11).exactly(1).and_return(inflate)
        process_incoming_message
        process_incoming_message
      end
    end

    describe "when the offer has higher client_max_window_bits" do
      before { offer["client_max_window_bits"] = 12 }

      it "includes client_max_window_bits in the response" do
        expect(response).to eq("client_max_window_bits" => 11)
      end

      it "uses context takeover and 11 window bits for inflating incoming messages" do
        response
        expect(Zlib::Inflate).to receive(:new).with(-11).exactly(1).and_return(inflate)
        process_incoming_message
        process_incoming_message
      end
    end

    describe "when the offer has lower client_max_window_bits" do
      before { offer["client_max_window_bits"] = 10 }

      it "includes client_max_window_bits in the response" do
        expect(response).to eq("client_max_window_bits" => 10)
      end

      it "uses context takeover and 10 window bits for inflating incoming messages" do
        response
        expect(Zlib::Inflate).to receive(:new).with(-10).exactly(1).and_return(inflate)
        process_incoming_message
        process_incoming_message
      end
    end
  end

  describe "with level" do
    before { options[:level] = Zlib::BEST_SPEED }

    it "sets the level of the deflate stream" do
      response
      expect(Zlib::Deflate).to receive(:new).with(Zlib::BEST_SPEED, -15, mem_level, strategy).and_return(deflate)
      process_outgoing_message
    end
  end

  describe "with mem_level" do
    before { options[:mem_level] = 5 }

    it "sets the mem_level of the deflate stream" do
      response
      expect(Zlib::Deflate).to receive(:new).with(level, -15, 5, strategy).and_return(deflate)
      process_outgoing_message
    end
  end

  describe "with strategy" do
    before { options[:strategy] = Zlib::FILTERED }

    it "sets the strategy of the deflate stream" do
      response
      expect(Zlib::Deflate).to receive(:new).with(level, -15, mem_level, Zlib::FILTERED).and_return(deflate)
      process_outgoing_message
    end
  end
end
