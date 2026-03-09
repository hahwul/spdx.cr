module Spdx
  struct LicenseException
    getter id : String
    getter name : String
    getter? deprecated : Bool

    def initialize(@id : String, @name : String, @deprecated : Bool = false)
    end

    def to_s(io : IO) : Nil
      io << id
    end
  end
end
