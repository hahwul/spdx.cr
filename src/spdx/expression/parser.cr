module Spdx
  module Expression
    class Parser
      @tokens : Array(Token)
      @pos : Int32 = 0

      def self.parse(input : String) : Node
        new(input).parse
      end

      def initialize(input : String)
        @tokens = Tokenizer.new(input).tokenize
      end

      def parse : Node
        raise ParseError.new("Empty expression") if current.type.eof?
        node = parse_or
        unless current.type.eof?
          raise ParseError.new("Unexpected token '#{current.value}' at position #{current.position}")
        end
        node
      end

      # OR has lowest precedence
      private def parse_or : Node
        left = parse_and
        while current.type.or?
          advance
          right = parse_and
          left = CompoundNode.new(CompoundNode::Operator::OR, left, right)
        end
        left
      end

      # AND has higher precedence than OR
      private def parse_and : Node
        left = parse_with
        while current.type.and?
          advance
          right = parse_with
          left = CompoundNode.new(CompoundNode::Operator::AND, left, right)
        end
        left
      end

      # WITH has higher precedence than AND
      private def parse_with : Node
        left = parse_primary
        if current.type.with?
          advance
          exception_id = expect_exception_id
          left = WithExceptionNode.new(left, exception_id)
        end
        left
      end

      private def parse_primary : Node
        case current.type
        when .l_paren?
          advance # consume '('
          node = parse_or
          expect(TokenType::RParen, "Expected ')'")
          node
        when .license_id?
          id = current.value
          advance
          if current.type.plus?
            advance
            LicenseNode.new(id, or_later: true)
          else
            LicenseNode.new(id)
          end
        when .license_ref?
          ref = current.value
          advance
          LicenseRefNode.new(ref)
        when .document_ref?
          doc_ref = current.value
          advance
          expect(TokenType::Colon, "Expected ':' after DocumentRef")
          unless current.type.license_ref?
            raise ParseError.new("Expected LicenseRef after DocumentRef at position #{current.position}")
          end
          lic_ref = current.value
          advance
          LicenseRefNode.new(lic_ref, doc_ref)
        else
          raise ParseError.new("Unexpected token '#{current.value}' at position #{current.position}")
        end
      end

      private def expect_exception_id : String
        unless current.type.license_id?
          raise ParseError.new("Expected exception identifier after WITH at position #{current.position}")
        end
        value = current.value
        advance
        value
      end

      private def expect(type : TokenType, message : String)
        unless current.type == type
          raise ParseError.new("#{message} at position #{current.position}")
        end
        advance
      end

      private def current : Token
        @tokens[@pos]
      end

      private def advance
        @pos += 1 if @pos < @tokens.size - 1
      end
    end
  end
end
