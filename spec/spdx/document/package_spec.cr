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
