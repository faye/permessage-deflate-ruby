# permessage_deflate [![Build status](https://secure.travis-ci.org/faye/permessage-deflate-ruby.svg)](http://travis-ci.org/faye/permessage-deflate-ruby)

Implements the
[permessage-deflate](https://tools.ietf.org/html/draft-ietf-hybi-permessage-compression)
WebSocket protocol extension as a plugin for
[websocket-extensions](https://github.com/faye/websocket-extensions-ruby).

## Installation

```
$ gem install permessage_deflate
```

## Usage

Add the plugin to your extensions:

```rb
require 'websocket/extensions'
require 'permessage_deflate'

exts = WebSocket::Extensions.new
exts.add(PermessageDeflate)
```

The extension can be configured, for example:

```rb
require 'websocket/extensions'
require 'permessage_deflate'

deflate = PermessageDeflate.configure(
  :level => Zlib::BEST_COMPRESSION,
  :max_window_bits => 13
)

exts = WebSocket::Extensions.new
exts.add(deflate)
```

The set of available options can be split into two sets: those that control the
session's compressor for outgoing messages and do not need to be communicated to
the peer, and those that are negotiated as part of the protocol. The settings
only affecting the compressor are described fully in the [Zlib
documentation](http://ruby-doc.org/stdlib-2.1.0/libdoc/zlib/rdoc/Zlib/Deflate.html#method-c-new):

* `:level`: sets the compression level, can be an integer from `0` to `9`, or
  one of the constants `Zlib::NO_COMPRESSION`, `Zlib::BEST_SPEED`,
  `Zlib::BEST_COMPRESSION`, or `Zlib::DEFAULT_COMPRESSION`
* `:mem_level`: sets how much memory the compressor allocates, can be an integer
  from `1` to `9`, or one of the constants `Zlib::MAX_MEM_LEVEL`, or
  `Zlib::DEF_MEM_LEVEL`
* `:strategy`: can be one of the constants `Zlib::FILTERED`,
  `Zlib::HUFFMAN_ONLY`, `Zlib::RLE`, `Zlib::FIXED`, or `Zlib::DEFAULT_STRATEGY`

The other options relate to settings that are negotiated via the protocol and
can be used to set the local session's behaviour and control that of the peer:

* `:no_context_takeover`: if `true`, stops the session reusing a deflate context
  between messages
* `:request_no_context_takeover`: if `true`, makes the session tell the other
  peer not to reuse a deflate context between messages
* `:max_window_bits`: an integer from `8` to `15` inclusive that sets the
  maximum size of the session's sliding window; a lower window size will be used
  if requested by the peer
* `:request_max_window_bits`: an integer from `8` to `15` inclusive to ask the
  other peer to use to set its maximum sliding window size, if supported
