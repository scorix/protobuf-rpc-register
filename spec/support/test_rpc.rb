module TestRpc
  module Messages
    class Version < Protobuf::Message
      required :string, :version, 0
    end
  end
end
