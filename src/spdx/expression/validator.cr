module Spdx
  module Expression
    # Result of validating an SPDX license expression AST.
    #
    # The validator splits findings into two buckets:
    #
    # * `errors`   — issues that mean the expression cannot be interpreted as a
    #                real SPDX expression (unknown license identifier, unknown
    #                exception). `valid?` is `false` whenever `errors` is
    #                non-empty.
    # * `warnings` — issues that are still parseable but should be cleaned up
    #                (deprecated identifier, non-canonical casing).
    struct ValidationResult
      getter errors : Array(String)
      getter warnings : Array(String)

      def initialize(@errors : Array(String) = [] of String,
                     @warnings : Array(String) = [] of String)
      end

      def valid? : Bool
        @errors.empty?
      end
    end

    class Validator
      # `license-ref = ["DocumentRef-"(idstring)":"]"LicenseRef-"(idstring)`
      # with `idstring = 1*(ALPHA / DIGIT / "-" / "." )` (SPDX 2.3, Annex D).
      LICENSE_REF_PATTERN  = /^LicenseRef-[A-Za-z0-9.\-]+$/
      DOCUMENT_REF_PATTERN = /^DocumentRef-[A-Za-z0-9.\-]+$/

      def self.validate(node : Node) : ValidationResult
        errors = [] of String
        warnings = [] of String
        validate_node(node, errors, warnings)
        ValidationResult.new(errors: errors, warnings: warnings)
      end

      private def self.validate_node(node : Node, errors : Array(String), warnings : Array(String))
        case node
        when ReservedNode
          # NONE / NOASSERTION are always valid standalone values.
        when LicenseNode
          if LicenseList.license?(node.id)
            lic = LicenseList.find_license(node.id)
            if lic.deprecated?
              warnings << "Deprecated license: #{node.id}"
            end
            if lic.id != node.id
              warnings << "Non-canonical casing: '#{node.id}' should be '#{lic.id}'"
            end
            # The `+` operator means "this version or later"; applying it to
            # an identifier that already encodes that (an `-or-later` id) is
            # redundant and SPDX deprecates the combination.
            if node.or_later? && node.id.downcase.ends_with?("-or-later")
              warnings << "Redundant '+': '#{node.id}' already means 'or later'"
            end
          else
            errors << "Unknown license: #{node.id}"
          end
        when WithExceptionNode
          validate_node(node.license, errors, warnings)
          if LicenseList.exception?(node.exception)
            exc = LicenseList.find_exception(node.exception)
            if exc.deprecated?
              warnings << "Deprecated exception: #{node.exception}"
            end
          else
            errors << "Unknown exception: #{node.exception}"
          end
        when LicenseRefNode
          # The referenced license itself is user-defined, so only the shape
          # of the identifier is checked against the ABNF.
          unless node.license_ref.matches?(LICENSE_REF_PATTERN)
            errors << "Malformed LicenseRef: #{node.license_ref}"
          end
          if doc_ref = node.document_ref
            unless doc_ref.matches?(DOCUMENT_REF_PATTERN)
              errors << "Malformed DocumentRef: #{doc_ref}"
            end
          end
        when CompoundNode
          validate_node(node.left, errors, warnings)
          validate_node(node.right, errors, warnings)
        end
      end
    end
  end
end
