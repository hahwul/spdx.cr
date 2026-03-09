module Spdx
  struct License
    getter id : String
    getter name : String
    getter? osi_approved : Bool
    getter? fsf_libre : Bool
    getter? deprecated : Bool

    def initialize(@id : String, @name : String, @osi_approved : Bool = false,
                   @fsf_libre : Bool = false, @deprecated : Bool = false)
    end

    def to_s(io : IO) : Nil
      io << id
    end
  end
end
