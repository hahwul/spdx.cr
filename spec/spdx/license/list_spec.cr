require "../../spec_helper"

describe Spdx::LicenseList do
  describe ".licenses" do
    it "returns a non-empty list" do
      Spdx::LicenseList.licenses.should_not be_empty
    end

    it "contains MIT" do
      Spdx::LicenseList.licenses.any? { |l| l.id == "MIT" }.should be_true
    end
  end

  describe ".exceptions" do
    it "returns a non-empty list" do
      Spdx::LicenseList.exceptions.should_not be_empty
    end

    it "contains Classpath-exception-2.0" do
      Spdx::LicenseList.exceptions.any? { |e| e.id == "Classpath-exception-2.0" }.should be_true
    end
  end

  describe ".find_license" do
    it "finds MIT" do
      lic = Spdx::LicenseList.find_license("MIT")
      lic.id.should eq("MIT")
      lic.osi_approved?.should be_true
    end

    it "is case-insensitive" do
      lic = Spdx::LicenseList.find_license("mit")
      lic.id.should eq("MIT")
    end

    it "raises for unknown license" do
      expect_raises(Spdx::UnknownLicenseError) do
        Spdx::LicenseList.find_license("NonExistent-1.0")
      end
    end
  end

  describe ".license?" do
    it "returns true for known license" do
      Spdx::LicenseList.license?("Apache-2.0").should be_true
    end

    it "returns false for unknown license" do
      Spdx::LicenseList.license?("Fake-1.0").should be_false
    end
  end

  describe ".find_exception" do
    it "finds Classpath-exception-2.0" do
      exc = Spdx::LicenseList.find_exception("Classpath-exception-2.0")
      exc.id.should eq("Classpath-exception-2.0")
    end

    it "is case-insensitive" do
      exc = Spdx::LicenseList.find_exception("classpath-exception-2.0")
      exc.id.should eq("Classpath-exception-2.0")
    end

    it "raises for unknown exception" do
      expect_raises(Spdx::UnknownExceptionError) do
        Spdx::LicenseList.find_exception("Fake-exception")
      end
    end
  end

  describe ".search" do
    it "finds licenses by id" do
      results = Spdx::LicenseList.search("apache")
      results.should_not be_empty
      results.any? { |l| l.id == "Apache-2.0" }.should be_true
    end

    it "finds licenses by name" do
      results = Spdx::LicenseList.search("MIT License")
      results.any? { |l| l.id == "MIT" }.should be_true
    end

    it "returns empty for no match" do
      results = Spdx::LicenseList.search("xyznonexistent123")
      results.should be_empty
    end
  end

  describe ".osi_approved" do
    it "returns only OSI-approved licenses" do
      osi = Spdx::LicenseList.osi_approved
      osi.should_not be_empty
      osi.all?(&.osi_approved?).should be_true
    end
  end

  describe ".fsf_libre" do
    it "returns only FSF libre licenses" do
      fsf = Spdx::LicenseList.fsf_libre
      fsf.should_not be_empty
      fsf.all?(&.fsf_libre?).should be_true
    end
  end
end
