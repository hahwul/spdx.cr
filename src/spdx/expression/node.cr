module Spdx
  module Expression
    abstract class Node
      abstract def to_s(io : IO) : Nil
    end

    class LicenseNode < Node
      getter id : String
      getter? or_later : Bool

      def initialize(@id : String, @or_later : Bool = false)
      end

      def to_s(io : IO) : Nil
        io << @id
        io << "+" if @or_later
      end
    end

    class LicenseRefNode < Node
      getter license_ref : String
      getter document_ref : String?

      def initialize(@license_ref : String, @document_ref : String? = nil)
      end

      def to_s(io : IO) : Nil
        if doc = @document_ref
          io << doc << ":" << @license_ref
        else
          io << @license_ref
        end
      end
    end

    class WithExceptionNode < Node
      getter license : Node
      getter exception : String

      def initialize(@license : Node, @exception : String)
      end

      def to_s(io : IO) : Nil
        @license.to_s(io)
        io << " WITH " << @exception
      end
    end

    class CompoundNode < Node
      enum Operator
        AND
        OR
      end

      getter left : Node
      getter right : Node
      getter operator : Operator

      def initialize(@operator : Operator, @left : Node, @right : Node)
      end

      def to_s(io : IO) : Nil
        wrap_left = @left.is_a?(CompoundNode) && @left.as(CompoundNode).operator != @operator
        wrap_right = @right.is_a?(CompoundNode) && @right.as(CompoundNode).operator != @operator

        if wrap_left
          io << "("
          @left.to_s(io)
          io << ")"
        else
          @left.to_s(io)
        end

        case @operator
        when .and? then io << " AND "
        when .or?  then io << " OR "
        end

        if wrap_right
          io << "("
          @right.to_s(io)
          io << ")"
        else
          @right.to_s(io)
        end
      end
    end
  end
end
