module Spdx
  module Expression
    enum TokenType
      LicenseId
      LicenseRef
      DocumentRef
      And
      Or
      With
      Plus
      LParen
      RParen
      Colon
      EOF
    end

    struct Token
      getter type : TokenType
      getter value : String
      getter position : Int32

      def initialize(@type : TokenType, @value : String, @position : Int32)
      end
    end

    class Tokenizer
      # Chars, not the String: `String#[]` by char index is O(n) on
      # non-ASCII input, which made tokenizing quadratic.
      @input : Array(Char)
      @pos : Int32 = 0
      @tokens : Array(Token)

      def initialize(input : String)
        @input = input.chars
        @tokens = [] of Token
      end

      def tokenize : Array(Token)
        @tokens.clear
        @pos = 0

        while @pos < @input.size
          skip_whitespace
          break if @pos >= @input.size

          char = @input[@pos]
          case char
          when '('
            @tokens << Token.new(TokenType::LParen, "(", @pos)
            @pos += 1
          when ')'
            @tokens << Token.new(TokenType::RParen, ")", @pos)
            @pos += 1
          when '+'
            # A '+' is only valid as a suffix immediately adjacent to a
            # license id (e.g. `MIT+`); that case is consumed inside
            # `read_word`. Reaching '+' here means it was preceded by
            # whitespace or stands alone, which the SPDX grammar forbids
            # (the ABNF concatenates `license-id "+"` with no separator).
            raise ParseError.new("'+' must immediately follow a license identifier (no whitespace) at position #{@pos}")
          when ':'
            @tokens << Token.new(TokenType::Colon, ":", @pos)
            @pos += 1
          else
            read_word
          end
        end

        @tokens << Token.new(TokenType::EOF, "", @pos)
        @tokens
      end

      private def skip_whitespace
        while @pos < @input.size && @input[@pos].ascii_whitespace?
          @pos += 1
        end
      end

      private def read_word
        start = @pos
        while @pos < @input.size
          c = @input[@pos]
          break if c.ascii_whitespace? || c == '(' || c == ')' || c == '+' || c == ':'
          @pos += 1
        end

        word = @input[start...@pos].join

        case word.upcase
        when "AND"
          @tokens << Token.new(TokenType::And, "AND", start)
        when "OR"
          @tokens << Token.new(TokenType::Or, "OR", start)
        when "WITH"
          @tokens << Token.new(TokenType::With, "WITH", start)
        else
          if word.starts_with?("DocumentRef-")
            @tokens << Token.new(TokenType::DocumentRef, word, start)
          elsif word.starts_with?("LicenseRef-")
            @tokens << Token.new(TokenType::LicenseRef, word, start)
          else
            @tokens << Token.new(TokenType::LicenseId, word, start)
          end

          # A trailing '+' is only meaningful when it is directly attached
          # to the identifier just read (the SPDX `license-id "+"` form).
          # Emit the Plus token here so non-adjacent '+' (handled in the
          # main loop) is rejected.
          if @pos < @input.size && @input[@pos] == '+'
            @tokens << Token.new(TokenType::Plus, "+", @pos)
            @pos += 1
            # SPDX 2.3 D.1: AND/OR need white space or parentheses on both
            # sides and WITH needs white space, so `MIT+AND x` is invalid.
            if @pos < @input.size && !(@input[@pos].ascii_whitespace? || @input[@pos] == ')')
              raise ParseError.new("'+' must be followed by white space, ')' or the end of the expression at position #{@pos}")
            end
          end
        end
      end
    end
  end
end
