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
      @input : String
      @pos : Int32 = 0
      @tokens : Array(Token)

      def initialize(@input : String)
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
            @tokens << Token.new(TokenType::Plus, "+", @pos)
            @pos += 1
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

        word = @input[start...@pos]

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
        end
      end
    end
  end
end
