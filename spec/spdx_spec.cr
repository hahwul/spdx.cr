require "./spec_helper"

describe Spdx do
  describe ".parse" do
    it "parses a simple license" do
      node = Spdx.parse("MIT")
      node.should be_a(Spdx::Expression::LicenseNode)
      node.to_s.should eq("MIT")
    end

    it "parses compound expression" do
      node = Spdx.parse("MIT AND Apache-2.0")
      node.to_s.should eq("MIT AND Apache-2.0")
    end
  end

  describe ".valid_expression?" do
    it "returns true for valid expression" do
      Spdx.valid_expression?("MIT").should be_true
    end

    it "returns false for invalid expression" do
      Spdx.valid_expression?("AND").should be_false
    end
  end

  describe ".validate_expression" do
    it "validates known licenses" do
      result = Spdx.validate_expression("MIT AND Apache-2.0")
      result.valid?.should be_true
      result.warnings.should be_empty
    end

    it "warns about unknown licenses" do
      result = Spdx.validate_expression("MIT AND FakeLicense-1.0")
      result.valid?.should be_true
      result.warnings.any? { |w| w.includes?("Unknown license") }.should be_true
    end
  end

  describe ".find_license" do
    it "finds a known license" do
      lic = Spdx.find_license("MIT")
      lic.id.should eq("MIT")
      lic.name.should eq("MIT License")
    end

    it "raises for unknown license" do
      expect_raises(Spdx::UnknownLicenseError) do
        Spdx.find_license("FakeLicense-999")
      end
    end
  end

  describe ".license?" do
    it "returns true for known license" do
      Spdx.license?("MIT").should be_true
    end

    it "returns false for unknown license" do
      Spdx.license?("FakeLicense-999").should be_false
    end

    it "is case-insensitive" do
      Spdx.license?("mit").should be_true
      Spdx.license?("MIT").should be_true
    end
  end
end
