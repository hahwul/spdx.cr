require "../../spec_helper"

describe Spdx::Expression::Validator do
  it "validates known licenses without warnings" do
    ast = Spdx::Expression::Parser.parse("MIT AND Apache-2.0")
    result = Spdx::Expression::Validator.validate(ast)
    result.valid?.should be_true
    result.warnings.should be_empty
  end

  it "warns about unknown licenses" do
    ast = Spdx::Expression::Parser.parse("FakeLicense-1.0")
    result = Spdx::Expression::Validator.validate(ast)
    result.valid?.should be_true
    result.warnings.size.should eq(1)
    result.warnings[0].should contain("Unknown license")
  end

  it "warns about deprecated licenses" do
    ast = Spdx::Expression::Parser.parse("GPL-2.0")
    result = Spdx::Expression::Validator.validate(ast)
    result.warnings.any? { |w| w.includes?("Deprecated") }.should be_true
  end

  it "validates WITH exceptions" do
    ast = Spdx::Expression::Parser.parse("GPL-2.0-only WITH Classpath-exception-2.0")
    result = Spdx::Expression::Validator.validate(ast)
    result.valid?.should be_true
  end

  it "warns about unknown exceptions" do
    ast = Spdx::Expression::Parser.parse("MIT WITH FakeException-1.0")
    result = Spdx::Expression::Validator.validate(ast)
    result.warnings.any? { |w| w.includes?("Unknown exception") }.should be_true
  end

  it "accepts LicenseRef without warnings" do
    ast = Spdx::Expression::Parser.parse("LicenseRef-custom-1")
    result = Spdx::Expression::Validator.validate(ast)
    result.valid?.should be_true
    result.warnings.should be_empty
  end
end
