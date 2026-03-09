module Spdx
  module Expression
    module Formatter
      extend self

      def format(node : Node) : String
        node.to_s
      end

      def normalize(expression : String) : String
        ast = Parser.parse(expression)
        format(ast)
      end
    end
  end
end
