require "../../spec_helper"

describe Spdx::License do
  it "creates a license struct" do
    lic = Spdx::License.new(id: "MIT", name: "MIT License", osi_approved: true, fsf_libre: true)
    lic.id.should eq("MIT")
    lic.name.should eq("MIT License")
    lic.osi_approved?.should be_true
    lic.fsf_libre?.should be_true
    lic.deprecated?.should be_false
  end

  it "converts to string" do
    lic = Spdx::License.new(id: "Apache-2.0", name: "Apache License 2.0")
    lic.to_s.should eq("Apache-2.0")
  end
end

describe Spdx::LicenseException do
  it "creates an exception struct" do
    exc = Spdx::LicenseException.new(id: "Classpath-exception-2.0", name: "Classpath exception 2.0")
    exc.id.should eq("Classpath-exception-2.0")
    exc.name.should eq("Classpath exception 2.0")
    exc.deprecated?.should be_false
  end

  it "converts to string" do
    exc = Spdx::LicenseException.new(id: "LLVM-exception", name: "LLVM Exception")
    exc.to_s.should eq("LLVM-exception")
  end
end
