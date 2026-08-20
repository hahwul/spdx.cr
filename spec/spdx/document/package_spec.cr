require "../../spec_helper"

describe Spdx::Package do
  it "creates a package" do
    pkg = Spdx::Package.new(
      spdx_id: "SPDXRef-Package",
      name: "TestPkg",
      download_location: "https://example.org/test.tar.gz",
      license_concluded: "MIT",
      license_declared: "MIT",
      copyright_text: "Copyright 2024"
    )
    pkg.name.should eq("TestPkg")
    pkg.spdx_id.should eq("SPDXRef-Package")
  end

  it "serializes to JSON and back" do
    pkg = Spdx::Package.new(
      spdx_id: "SPDXRef-Pkg",
      name: "TestPkg",
      download_location: "https://example.org/test.tar.gz",
      license_concluded: "Apache-2.0",
      license_declared: "Apache-2.0",
      copyright_text: "Copyright 2024"
    )
    pkg.version_info = "1.0.0"
    pkg.homepage = "https://example.org"

    json = pkg.to_json
    parsed = Spdx::Package.from_json(json)
    parsed.name.should eq("TestPkg")
    parsed.version_info.should eq("1.0.0")
    parsed.homepage.should eq("https://example.org")
  end
end

describe Spdx::PrimaryPackagePurpose do
  it "serializes OPERATING_SYSTEM with the JSON schema spelling" do
    # The SPDX 2.3 JSON schema enumerates `OPERATING_SYSTEM`, while the
    # tag-value format (SPDX 2.3 §7.24) uses `OPERATING-SYSTEM`.
    pkg = Spdx::Package.new(
      spdx_id: "SPDXRef-Pkg", name: "P", download_location: "NOASSERTION",
      license_concluded: "MIT", license_declared: "MIT", copyright_text: "c"
    )
    pkg.primary_package_purpose = Spdx::PrimaryPackagePurpose::OPERATING_SYSTEM

    pkg.to_json.should contain(%("primaryPackagePurpose":"OPERATING_SYSTEM"))
    Spdx::PrimaryPackagePurpose::OPERATING_SYSTEM.to_s.should eq("OPERATING-SYSTEM")

    parsed = Spdx::Package.from_json(pkg.to_json)
    parsed.primary_package_purpose.should eq(Spdx::PrimaryPackagePurpose::OPERATING_SYSTEM)
  end
end

describe Spdx::ExternalRefCategory do
  it "accepts both the hyphenated and underscored spellings" do
    Spdx::ExternalRefCategory.from_string("PACKAGE-MANAGER").should eq(Spdx::ExternalRefCategory::PACKAGE_MANAGER)
    Spdx::ExternalRefCategory.from_string("PACKAGE_MANAGER").should eq(Spdx::ExternalRefCategory::PACKAGE_MANAGER)
    Spdx::ExternalRefCategory.from_string("PERSISTENT_ID").should eq(Spdx::ExternalRefCategory::PERSISTENT_ID)
  end

  it "always writes the hyphenated SPDX 2.3 spelling" do
    Spdx::ExternalRefCategory::PACKAGE_MANAGER.to_s.should eq("PACKAGE-MANAGER")
    Spdx::ExternalRefCategory::PACKAGE_MANAGER.to_json.should eq(%("PACKAGE-MANAGER"))
  end

  it "raises FormatError on an unknown category" do
    expect_raises(Spdx::FormatError, "Unknown external reference category: NOPE") do
      Spdx::ExternalRefCategory.from_string("NOPE")
    end
  end
end

describe Spdx::Relationship do
  it "serializes to JSON and back" do
    rel = Spdx::Relationship.new(
      spdx_element_id: "SPDXRef-DOCUMENT",
      relationship_type: Spdx::RelationshipType::DESCRIBES,
      related_spdx_element: "SPDXRef-Package"
    )
    json = rel.to_json
    parsed = Spdx::Relationship.from_json(json)
    parsed.spdx_element_id.should eq("SPDXRef-DOCUMENT")
    parsed.relationship_type.should eq(Spdx::RelationshipType::DESCRIBES)
    parsed.related_spdx_element.should eq("SPDXRef-Package")
  end
end

describe Spdx::Checksum do
  it "serializes to JSON and back" do
    cs = Spdx::Checksum.new(
      algorithm: Spdx::ChecksumAlgorithm::SHA256,
      value: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    )
    json = cs.to_json
    parsed = Spdx::Checksum.from_json(json)
    parsed.algorithm.should eq(Spdx::ChecksumAlgorithm::SHA256)
    parsed.value.should eq("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  end
end
