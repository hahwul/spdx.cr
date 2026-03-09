require "./spdx/version"
require "./spdx/error"
require "./spdx/license/license"
require "./spdx/license/exception"
require "./spdx/license/list"
require "./spdx/expression/token"
require "./spdx/expression/node"
require "./spdx/expression/parser"
require "./spdx/expression/validator"
require "./spdx/expression/formatter"
require "./spdx/document/*"
require "./spdx/format/tag_value/*"
require "./spdx/format/json/*"

module Spdx
  def self.parse(expression : String) : Expression::Node
    Expression::Parser.parse(expression)
  end

  def self.valid_expression?(expression : String) : Bool
    Expression::Parser.parse(expression)
    true
  rescue ParseError
    false
  end

  def self.validate_expression(expression : String) : Expression::ValidationResult
    ast = Expression::Parser.parse(expression)
    Expression::Validator.validate(ast)
  end

  def self.find_license(id : String) : License
    LicenseList.find_license(id)
  end

  def self.license?(id : String) : Bool
    LicenseList.license?(id)
  end

  def self.find_exception(id : String) : LicenseException
    LicenseList.find_exception(id)
  end

  def self.exception?(id : String) : Bool
    LicenseList.exception?(id)
  end
end
