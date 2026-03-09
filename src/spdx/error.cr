module Spdx
  class Error < Exception
  end

  class ParseError < Error
  end

  class UnknownLicenseError < Error
    getter license_id : String

    def initialize(@license_id : String)
      super("Unknown SPDX license identifier: #{@license_id}")
    end
  end

  class UnknownExceptionError < Error
    getter exception_id : String

    def initialize(@exception_id : String)
      super("Unknown SPDX license exception: #{@exception_id}")
    end
  end

  class DocumentError < Error
  end

  class ValidationError < Error
    getter errors : Array(String)

    def initialize(@errors : Array(String))
      super("Validation failed: #{@errors.join(", ")}")
    end

    def initialize(message : String)
      @errors = [message]
      super(message)
    end
  end

  class FormatError < Error
  end
end
