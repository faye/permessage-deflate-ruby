require "spec_helper"

describe PermessageDeflate::ClientSession do
  let(:ext)       { PermessageDeflate.configure(options) }
  let(:session)   { ext.create_client_session }
  let(:options)   { {} }
  let(:offer)     { session.generate_offer }
  let(:response)  { {} }
  let(:activate)  { session.activate(response) }

  let(:deflate)   { double(:deflate, :deflate => [0x00, 0x00, 0xff, 0xff].pack("C*")) }
  let(:inflate)   { double(:inflate, :inflate => [0x00, 0x00, 0xff, 0xff].pack("C*")) }
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
    it "indicates support for client_max_window_bits" do
      expect(offer).to eq("client_max_window_bits" => true)
    end

    describe "with an empty response" do
      it "accepts the response" do
        expect(activate).to be true
      end

      it "uses context takeover and 15 window bits for inflating incoming messages" do
        activate
        expect(Zlib::Inflate).to receive(:new).with(-15).exactly(1).and_return(inflate)
        process_incoming_message
        process_incoming_message
      end

      it "uses context takeover and 15 window bits for deflating outgoing messages" do
        activate
        expect(Zlib::Deflate).to receive(:new).with(level, -15, mem_level, strategy).exactly(1).and_return(deflate)
        process_outgoing_message
        process_outgoing_message
      end
    end

    describe "when the response includes server_no_context_takeover" do
      before { response["server_no_context_takeover"] = true }

      it "accepts the response" do
        expect(activate).to be true
      end

      it "uses no context takeover and 15 window bits for inflating incoming messages" do
        activate
        expect(Zlib::Inflate).to receive(:new).with(-15).exactly(2).and_return(inflate)
        expect(inflate).to receive(:finish).exactly(2)
        expect(inflate).to receive(:close).exactly(2)
        process_incoming_message
        process_incoming_message
      end
    end

    describe "when the response includes client_no_context_takeover" do
      before { response["client_no_context_takeover"] = true }

      it "accepts the response" do
        expect(activate).to be true
      end

      it "uses no context takeover and 15 window bits for deflating outgoing messages" do
        activate
        expect(Zlib::Deflate).to receive(:new).with(level, -15, mem_level, strategy).exactly(2).and_return(deflate)
        expect(deflate).to receive(:finish).exactly(2)
        expect(deflate).to receive(:close).exactly(2)
        process_outgoing_message
        process_outgoing_message
      end
    end

    describe "when the response includes server_max_window_bits" do
      before { response["server_max_window_bits"] = 8 }

      it "accepts the response" do
        expect(activate).to be true
      end

      it "uses context takeover and 9 window bits for inflating incoming messages" do
        activate
        expect(Zlib::Inflate).to receive(:new).with(-9).exactly(1).and_return(inflate)
        process_incoming_message
        process_incoming_message
      end
    end

    describe "when the response includes invalid server_max_window_bits" do
      before { response["server_max_window_bits"] = 20 }

      it "rejects the response" do
        expect(activate).to be false
      end
    end

    describe "when the response includes client_max_window_bits" do
      before { response["client_max_window_bits"] = 8 }

      it "accepts the response" do
        expect(activate).to be true
      end

      it "uses context takeover and 9 window bits for deflating outgoing messages" do
        activate
        expect(Zlib::Deflate).to receive(:new).with(level, -9, mem_level, strategy).exactly(1).and_return(deflate)
        process_outgoing_message
        process_outgoing_message
      end
    end

    describe "when the response includes invalid client_max_window_bits" do
      before { response["client_max_window_bits"] = 20 }

      it "rejects the response" do
        expect(activate).to be false
      end
    end
  end

  describe "with no_context_takeover" do
    before { options[:no_context_takeover] = true }

    it "sends client_no_context_takeover" do
      expect(offer).to eq(
        "client_no_context_takeover" => true,
        "client_max_window_bits"     => true
      )
    end

    describe "with an empty response" do
      it "accepts the response" do
        expect(activate).to be true
      end

      it "uses no context takeover and 15 window bits for deflating outgoing messages" do
        activate
        expect(Zlib::Deflate).to receive(:new).with(level, -15, mem_level, strategy).exactly(2).and_return(deflate)
        expect(deflate).to receive(:finish).exactly(2)
        expect(deflate).to receive(:close).exactly(2)
        process_outgoing_message
        process_outgoing_message
      end
    end
  end

  describe "with max_window_bits" do
    before { options[:max_window_bits] = 9 }

    it "sends client_max_window_bits" do
      expect(offer).to eq("client_max_window_bits" => 9)
    end

    describe "with an empty response" do
      it "accepts the response" do
        expect(activate).to be true
      end

      it "uses context takeover and 9 window bits for deflating outgoing messages" do
        activate
        expect(Zlib::Deflate).to receive(:new).with(level, -9, mem_level, strategy).exactly(1).and_return(deflate)
        process_outgoing_message
        process_outgoing_message
      end
    end

    describe "when the response has higher client_max_window_bits" do
      before { response["client_max_window_bits"] = 10 }

      it "rejects the response" do
        expect(activate).to be false
      end
    end

    describe "when the response has lower client_max_window_bits" do
      before { response["client_max_window_bits"] = 8 }

      it "accepts the response" do
        expect(activate).to be true
      end

      it "uses context takeover and 9 window bits for deflating outgoing messages" do
        activate
        expect(Zlib::Deflate).to receive(:new).with(level, -9, mem_level, strategy).exactly(1).and_return(deflate)
        process_outgoing_message
        process_outgoing_message
      end
    end
  end

  describe "with invalid max_window_bits" do
    before { options[:max_window_bits] = 20 }

    it "raises when generating the offer" do
      expect { offer }.to raise_error(PermessageDeflate::ConfigurationError)
    end
  end

  describe "with request_no_context_takeover" do
    before { options[:request_no_context_takeover] = true }

    it "sends server_no_context_takeover" do
      expect(offer).to eq(
        "client_max_window_bits"     => true,
        "server_no_context_takeover" => true
      )
    end

    describe "with an empty response" do
      it "rejects the response" do
        expect(activate).to be false
      end
    end

    describe "when the response includes server_no_context_takeover" do
      before { response["server_no_context_takeover"] = true }

      it "accepts the response" do
        expect(activate).to be true
      end

      it "uses no context takeover and 15 window bits for inflating incoming messages" do
        activate
        expect(Zlib::Inflate).to receive(:new).with(-15).exactly(2).and_return(inflate)
        expect(inflate).to receive(:finish).exactly(2)
        expect(inflate).to receive(:close).exactly(2)
        process_incoming_message
        process_incoming_message
      end
    end
  end

  describe "with request_max_window_bits" do
    before { options[:request_max_window_bits] = 12 }

    it "sends server_max_window_bits" do
      expect(offer).to eq(
        "client_max_window_bits" => true,
        "server_max_window_bits" => 12
      )
    end

    describe "with an empty response" do
      it "rejects the response" do
        expect(activate).to be false
      end
    end

    describe "when the response has higher server_max_window_bits" do
      before { response["server_max_window_bits"] = 13 }

      it "rejects the response" do
        expect(activate).to be false
      end
    end

    describe "when the response has lower server_max_window_bits" do
      before { response["server_max_window_bits"] = 11 }

      it "accepts the response" do
        expect(activate).to be true
      end

      it "uses context takeover and 11 window bits for inflating incoming messages" do
        activate
        expect(Zlib::Inflate).to receive(:new).with(-11).exactly(1).and_return(inflate)
        process_incoming_message
        process_incoming_message
      end
    end
  end

  describe "with invalid request_max_window_bits" do
    before { options[:request_max_window_bits] = 20 }

    it "raises when generating an offer" do
      expect { offer }.to raise_error(PermessageDeflate::ConfigurationError)
    end
  end

  describe "with level" do
    before { options[:level] = Zlib::BEST_SPEED }

    it "sets the level of the deflate stream" do
      activate
      expect(Zlib::Deflate).to receive(:new).with(Zlib::BEST_SPEED, -15, mem_level, strategy).and_return(deflate)
      process_outgoing_message
    end
  end

  describe "with mem_level" do
    before { options[:mem_level] = 5 }

    it "sets the mem_level of the deflate stream" do
      activate
      expect(Zlib::Deflate).to receive(:new).with(level, -15, 5, strategy).and_return(deflate)
      process_outgoing_message
    end
  end

  describe "with strategy" do
    before { options[:strategy] = Zlib::FILTERED }

    it "sets the strategy of the deflate stream" do
      activate
      expect(Zlib::Deflate).to receive(:new).with(level, -15, mem_level, Zlib::FILTERED).and_return(deflate)
      process_outgoing_message
    end
  end
end
