module Spdx
  module Format
    # Casing alias for `Spdx::Format::Json` that matches Crystal stdlib's
    # `JSON` module. Both `Spdx::Format::Json` and `Spdx::Format::JSON`
    # resolve to the same Parser/Generator.
    module JSON
      alias Parser = Json::Parser
      alias Generator = Json::Generator
    end
  end
end
