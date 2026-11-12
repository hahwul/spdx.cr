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

  it "accepts NONE and NOASSERTION as valid" do
    ["NONE", "NOASSERTION"].each do |value|
      ast = Spdx::Expression::Parser.parse(value)
      result = Spdx::Expression::Validator.validate(ast)
      result.valid?.should be_true
      result.errors.should be_empty
      result.warnings.should be_empty
    end
  end

  # The parser rejects these; only nodes built in code reach the validator.
  it "flags a LicenseRef whose idstring is empty or malformed" do
    # license-ref = ["DocumentRef-"(idstring)":"]"LicenseRef-"(idstring)
    ["LicenseRef-", "LicenseRef-bad_ref"].each do |ref|
      result = Spdx::Expression::Validator.validate(Spdx::Expression::LicenseRefNode.new(ref))
      result.valid?.should be_false
      result.errors.any?(&.includes?("Malformed LicenseRef")).should be_true
    end
  end

  it "reports (does not raise on) invalid UTF-8 in a LicenseRef or DocumentRef" do
    bad = String.new(Bytes[0x4c, 0x69, 0x63, 0x65, 0x6e, 0x73, 0x65, 0x52, 0x65, 0x66, 0x2d, 0xff])
    result = Spdx::Expression::Validator.validate(Spdx::Expression::LicenseRefNode.new(bad, bad))
    result.errors.any?(&.includes?("Malformed LicenseRef")).should be_true
    result.errors.any?(&.includes?("Malformed DocumentRef")).should be_true
    Spdx::Expression::Validator.validate(Spdx::Expression::LicenseNode.new(bad)).valid?.should be_false
  end

  it "flags a malformed DocumentRef" do
    ast = Spdx::Expression::LicenseRefNode.new("LicenseRef-custom-1", "DocumentRef-bad_ref")
    result = Spdx::Expression::Validator.validate(ast)
    result.valid?.should be_false
    result.errors.any?(&.includes?("Malformed DocumentRef")).should be_true
  end

  it "accepts a well-formed DocumentRef:LicenseRef pair" do
    ast = Spdx::Expression::Parser.parse("DocumentRef-ext1:LicenseRef-custom-1")
    Spdx::Expression::Validator.validate(ast).valid?.should be_true
  end

  it "warns on a redundant '+' applied to an -or-later identifier" do
    ast = Spdx::Expression::Parser.parse("GPL-3.0-or-later+")
    result = Spdx::Expression::Validator.validate(ast)
    result.valid?.should be_true
    result.warnings.any?(&.includes?("Redundant '+'")).should be_true
  end

  # SPDX 2.3 D.2: exception ids match case-insensitively, like license ids.
  it "warns on non-canonical exception casing" do
    ast = Spdx::Expression::Parser.parse("GPL-2.0-only WITH classpath-exception-2.0")
    result = Spdx::Expression::Validator.validate(ast)
    result.valid?.should be_true
    result.warnings.should contain("Non-canonical casing: 'classpath-exception-2.0' should be 'Classpath-exception-2.0'")
  end
end
