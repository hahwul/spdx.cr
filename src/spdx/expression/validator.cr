module Spdx
  module Expression
    struct ValidationResult
      getter warnings : Array(String)
      getter? valid : Bool

      def initialize(@valid : Bool, @warnings : Array(String) = [] of String)
      end
    end

    class Validator
      def self.validate(node : Node) : ValidationResult
        warnings = [] of String
        validate_node(node, warnings)
        ValidationResult.new(valid: true, warnings: warnings)
      end

      private def self.validate_node(node : Node, warnings : Array(String))
        case node
        when LicenseNode
          unless LicenseList.license?(node.id)
            warnings << "Unknown license: #{node.id}"
          else
            lic = LicenseList.find_license(node.id)
            if lic.deprecated?
              warnings << "Deprecated license: #{node.id}"
            end
            if lic.id != node.id
              warnings << "Non-canonical casing: '#{node.id}' should be '#{lic.id}'"
            end
          end
        when WithExceptionNode
          validate_node(node.license, warnings)
          unless LicenseList.exception?(node.exception)
            warnings << "Unknown exception: #{node.exception}"
          else
            exc = LicenseList.find_exception(node.exception)
            if exc.deprecated?
              warnings << "Deprecated exception: #{node.exception}"
            end
          end
        when LicenseRefNode
          # LicenseRef and DocumentRef are user-defined, always valid
        when CompoundNode
          validate_node(node.left, warnings)
          validate_node(node.right, warnings)
        end
      end
    end
  end
end
