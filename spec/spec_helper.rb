require File.expand_path("../../lib/permessage_deflate", __FILE__)

class Message < Struct.new(:data, :rsv1)
end
