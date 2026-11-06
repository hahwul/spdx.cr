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

  describe "embedded snapshot (SPDX License List v3.29.0)" do
    it "reports the list version" do
      Spdx::LicenseList.version.should eq("3.29.0")
      Spdx.license_list_version.should eq("3.29.0")
    end

    it "resolves a license and an exception added in v3.29.0" do
      Spdx::LicenseList.find_license("BSD-ask-to-endorse").osi_approved?.should be_true
      Spdx::LicenseList.exception?("Google-Patent-WebM").should be_true
      result = Spdx.validate_expression("BSD-ask-to-endorse WITH Google-Patent-WebM")
      result.errors.should be_empty
      result.warnings.should be_empty
    end

    it "carries OSI approval changed in v3.29.0" do
      Spdx::LicenseList.find_license("CDDL-1.1").osi_approved?.should be_true
    end

    # v3.27.0 through v3.29.0 deprecated no IDs; pin the existing ones.
    it "still reports deprecated IDs as deprecated" do
      Spdx::LicenseList.find_license("GPL-2.0").deprecated?.should be_true
      Spdx::LicenseList.find_exception("Nokia-Qt-exception-1.1").deprecated?.should be_true
    end
  end
end
