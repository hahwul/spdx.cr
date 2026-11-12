module Spdx
  module Expression
    class Parser
      # Hard cap on how deep parenthesised SPDX expressions may nest. SPDX
      # license expressions never need real-world depth in the hundreds —
      # this defends the recursive-descent parser against stack-overflow
      # DoS from a hostile SBOM (e.g. ten thousand nested parens).
      MAX_DEPTH = 256
      # Each AND/OR adds a level to the (left-deep) AST, which `to_s`, the
      # validator and callers walk recursively; an unbounded operator chain
      # overflows the stack (uncatchable) on a hostile 1 MB expression.
      MAX_OPERATORS = 10_000

      @tokens : Array(Token)
      @pos : Int32 = 0
      @depth : Int32 = 0
      @operators : Int32 = 0
      # Whether the primary expression just parsed was a parenthesized group,
      # which the SPDX grammar forbids as the left operand of `WITH`.
      @last_primary_parenthesised : Bool = false

      def self.parse(input : String) : Node
        new(input).parse
      end

      def initialize(input : String)
        # The validator's regexes raise ArgumentError on malformed UTF-8.
        raise ParseError.new("Expression is not valid UTF-8") unless input.valid_encoding?
        @tokens = Tokenizer.new(input).tokenize
      end

      def parse : Node
        raise ParseError.new("Empty expression") if current.type.eof?

        # `NONE` / `NOASSERTION` are reserved values that stand alone; they
        # are not part of the compound-expression grammar and may not be
        # combined with other licenses.
        if current.type.license_id? &&
           (current.value == ReservedNode::NONE || current.value == ReservedNode::NOASSERTION)
          value = current.value
          advance
          unless current.type.eof?
            raise ParseError.new("'#{value}' cannot be combined with other license expressions at position #{current.position}")
          end
          return ReservedNode.new(value)
        end

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
          count_operator
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
          count_operator
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
          # The SPDX ABNF only allows `simple-expression "WITH"
          # license-exception-id`; a parenthesised group is a
          # compound-expression and may not carry an exception.
          if @last_primary_parenthesised
            raise ParseError.new("'WITH' may only follow a simple license expression, not a parenthesized expression, at position #{current.position}")
          end
          advance
          exception_id = expect_exception_id
          left = WithExceptionNode.new(left, exception_id)
        end
        left
      end

      private def parse_primary : Node
        @last_primary_parenthesised = false
        case current.type
        when .l_paren?
          advance # consume '('
          if @depth >= MAX_DEPTH
            raise ParseError.new("Expression nesting exceeds maximum depth (#{MAX_DEPTH}) at position #{current.position}")
          end
          @depth += 1
          begin
            node = parse_or
          ensure
            @depth -= 1
          end
          expect(TokenType::RParen, "Expected ')'")
          @last_primary_parenthesised = true
          node
        when .license_id?
          id = current.value
          # NONE / NOASSERTION are standalone reserved values handled in
          # `parse`; reaching here means one appears inside a compound
          # expression, which the SPDX grammar disallows.
          if id == ReservedNode::NONE || id == ReservedNode::NOASSERTION
            raise ParseError.new("'#{id}' cannot be combined with other license expressions at position #{current.position}")
          end
          advance
          if current.type.plus?
            advance
            LicenseNode.new(id, or_later: true)
          else
            LicenseNode.new(id)
          end
        when .license_ref?
          ref = expect_idstring(Validator::LICENSE_REF_PATTERN, "LicenseRef")
          LicenseRefNode.new(ref)
        when .document_ref?
          # `"DocumentRef-"(idstring)":""LicenseRef-"(idstring)` is a single
          # ABNF concatenation (SPDX 2.3 D.1/D.3): no white space around ':'.
          adjacent_at = current.position + current.value.size
          doc_ref = expect_idstring(Validator::DOCUMENT_REF_PATTERN, "DocumentRef")
          unless current.type.colon? && current.position == adjacent_at
            raise ParseError.new("Expected ':' immediately after DocumentRef at position #{current.position}")
          end
          advance
          unless current.type.license_ref? && current.position == adjacent_at + 1
            raise ParseError.new("Expected LicenseRef immediately after 'DocumentRef-…:' at position #{current.position}")
          end
          lic_ref = expect_idstring(Validator::LICENSE_REF_PATTERN, "LicenseRef")
          LicenseRefNode.new(lic_ref, doc_ref)
        else
          raise ParseError.new("Unexpected token '#{current.value}' at position #{current.position}")
        end
      end

      private def count_operator : Nil
        @operators += 1
        if @operators > MAX_OPERATORS
          raise ParseError.new("Expression has more than #{MAX_OPERATORS} AND/OR operators at position #{current.position}")
        end
      end

      # Annex D: `idstring = 1*(ALPHA / DIGIT / "-" / ".")`, so an empty or
      # non-ASCII-alphanumeric idstring after the prefix is a syntax error.
      private def expect_idstring(pattern : Regex, kind : String) : String
        value = current.value
        unless value.matches?(pattern)
          raise ParseError.new("Malformed #{kind}: #{value} at position #{current.position}")
        end
        advance
        value
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
