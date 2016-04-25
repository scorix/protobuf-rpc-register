module TestRpc
  module Services

  end

  module Messages
    class Version < Protobuf::Message
      required :string, :version, 0
    end
  end

  module Clients

  end
end
