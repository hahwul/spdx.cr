require "../../spec_helper"

describe Spdx::SpdxDocument do
  it "creates a minimal valid document" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.relationships = [
      Spdx::Relationship.new(
        spdx_element_id: "SPDXRef-DOCUMENT",
        relationship_type: Spdx::RelationshipType::DESCRIBES,
        related_spdx_element: "SPDXRef-Package"
      ),
    ]
    doc.spdx_version.should eq("SPDX-2.3")
    doc.data_license.should eq("CC0-1.0")
    doc.valid?.should be_true
  end

  it "validates required fields" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.valid?.should be_false
    doc.validate.should contain("spdxVersion is required")
  end

  it "validates data license must be CC0-1.0" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "MIT",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.validate.should contain("dataLicense must be 'CC0-1.0'")
  end

  it "validates documentNamespace must be a valid URI" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "not-a-uri",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.validate.should contain("documentNamespace must be a valid URI")
  end

  it "validates creator format" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["invalid-creator"]
      )
    )
    doc.validate.any? { |e| e.includes?("Tool:") }.should be_true
  end

  it "validates created date ISO 8601 format" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01",
        creators: ["Tool: test"]
      )
    )
    doc.validate.any? { |e| e.includes?("ISO 8601") }.should be_true
  end

  it "validates DESCRIBES relationship is required" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.validate.should contain("document must have at least one DESCRIBES relationship")
  end

  it "validates package verification code when filesAnalyzed is true" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.packages = [
      Spdx::Package.new(
        spdx_id: "SPDXRef-Package",
        name: "TestPkg",
        download_location: "https://example.org/pkg",
        license_concluded: "MIT",
        license_declared: "MIT",
        copyright_text: "Copyright 2024"
      ),
    ]
    doc.validate.any? { |e| e.includes?("packageVerificationCode") }.should be_true
  end

  it "serializes to JSON" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    json = doc.to_json
    parsed = Spdx::SpdxDocument.from_json(json)
    parsed.spdx_version.should eq("SPDX-2.3")
    parsed.name.should eq("Test")
  end
end
