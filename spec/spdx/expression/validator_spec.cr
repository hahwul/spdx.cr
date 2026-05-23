require "../../spec_helper"

describe Spdx::Expression::Validator do
  it "validates known licenses without errors or warnings" do
    ast = Spdx::Expression::Parser.parse("MIT AND Apache-2.0")
    result = Spdx::Expression::Validator.validate(ast)
    result.valid?.should be_true
    result.errors.should be_empty
    result.warnings.should be_empty
  end

  it "treats unknown licenses as errors (valid? false)" do
    ast = Spdx::Expression::Parser.parse("FakeLicense-1.0")
    result = Spdx::Expression::Validator.validate(ast)
    result.valid?.should be_false
    result.errors.size.should eq(1)
    result.errors[0].should contain("Unknown license")
    result.warnings.should be_empty
  end

  it "treats deprecated licenses as warnings (valid? remains true)" do
    ast = Spdx::Expression::Parser.parse("GPL-2.0")
    result = Spdx::Expression::Validator.validate(ast)
    result.valid?.should be_true
    result.errors.should be_empty
    result.warnings.any?(&.includes?("Deprecated")).should be_true
  end

  it "validates WITH exceptions" do
    ast = Spdx::Expression::Parser.parse("GPL-2.0-only WITH Classpath-exception-2.0")
    result = Spdx::Expression::Validator.validate(ast)
    result.valid?.should be_true
    result.errors.should be_empty
  end

  it "treats unknown exceptions as errors (valid? false)" do
    ast = Spdx::Expression::Parser.parse("MIT WITH FakeException-1.0")
    result = Spdx::Expression::Validator.validate(ast)
    result.valid?.should be_false
    result.errors.any?(&.includes?("Unknown exception")).should be_true
  end

  it "accepts LicenseRef without errors or warnings" do
    ast = Spdx::Expression::Parser.parse("LicenseRef-custom-1")
    result = Spdx::Expression::Validator.validate(ast)
    result.valid?.should be_true
    result.errors.should be_empty
    result.warnings.should be_empty
  end

  it "collects errors across compound expressions" do
    ast = Spdx::Expression::Parser.parse("MIT AND FakeA AND FakeB")
    result = Spdx::Expression::Validator.validate(ast)
    result.valid?.should be_false
    result.errors.size.should eq(2)
  end
end
