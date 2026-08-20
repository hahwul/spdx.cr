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
    doc.packages = [
      Spdx::Package.new(
        spdx_id: "SPDXRef-Package",
        name: "TestPkg",
        download_location: "https://example.org/pkg",
        license_concluded: "MIT",
        license_declared: "MIT",
        copyright_text: "Copyright 2024"
      ).tap(&.files_analyzed=(false)),
    ]
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
    doc.validate.any?(&.includes?("Tool:")).should be_true
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
    doc.validate.any?(&.includes?("ISO 8601")).should be_true
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
    doc.validate.any?(&.includes?("must declare what it describes")).should be_true
  end

  it "accepts documentDescribes in place of a DESCRIBES relationship" do
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
      ).tap(&.files_analyzed=(false)),
    ]
    doc.document_describes = ["SPDXRef-Package"]
    doc.validate.any?(&.includes?("must declare what it describes")).should be_false
  end

  it "flags a relationship referencing an undefined SPDXID" do
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
        related_spdx_element: "SPDXRef-Nope"
      ),
    ]
    doc.validate.any?(&.includes?("undefined element 'SPDXRef-Nope'")).should be_true
  end

  it "accepts NOASSERTION and external DocumentRef relationship targets" do
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
    doc.external_document_refs = [
      Spdx::ExternalDocumentRef.new(
        external_document_id: "DocumentRef-ext",
        spdx_document: "https://example.org/ext",
        checksum: Spdx::Checksum.new(algorithm: Spdx::ChecksumAlgorithm::SHA1, value: "0" * 40)
      ),
    ]
    doc.document_describes = ["SPDXRef-DOCUMENT"]
    doc.relationships = [
      Spdx::Relationship.new(
        spdx_element_id: "SPDXRef-DOCUMENT",
        relationship_type: Spdx::RelationshipType::DESCRIBES,
        related_spdx_element: "NOASSERTION"
      ),
      Spdx::Relationship.new(
        spdx_element_id: "SPDXRef-DOCUMENT",
        relationship_type: Spdx::RelationshipType::DESCRIBES,
        related_spdx_element: "DocumentRef-ext:SPDXRef-Thing"
      ),
    ]
    doc.validate.none?(&.includes?("undefined element")).should be_true
  end

  it "flags duplicate SPDXIDs" do
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
        spdx_id: "SPDXRef-Dup", name: "A",
        download_location: "https://example.org/a",
        license_concluded: "MIT", license_declared: "MIT",
        copyright_text: "c"
      ).tap(&.files_analyzed=(false)),
      Spdx::Package.new(
        spdx_id: "SPDXRef-Dup", name: "B",
        download_location: "https://example.org/b",
        license_concluded: "MIT", license_declared: "MIT",
        copyright_text: "c"
      ).tap(&.files_analyzed=(false)),
    ]
    doc.document_describes = ["SPDXRef-Dup"]
    doc.validate.any?(&.includes?("duplicate SPDXID 'SPDXRef-Dup'")).should be_true
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
    doc.validate.any?(&.includes?("packageVerificationCode")).should be_true
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

  it "flags an invalid SPDX license expression in a package field" do
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
        license_concluded: "NOT-A-LICENSE AND ALSO-FAKE",
        license_declared: "garbage(((",
        copyright_text: "Copyright 2024"
      ).tap(&.files_analyzed=(false)),
    ]
    errors = doc.validate
    errors.any?(&.includes?("licenseConcluded")).should be_true
    errors.any?(&.includes?("licenseDeclared")).should be_true
  end

  it "accepts NOASSERTION in a package license field" do
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
        license_concluded: "NOASSERTION",
        license_declared: "MIT OR Apache-2.0",
        copyright_text: "Copyright 2024"
      ).tap(&.files_analyzed=(false)),
    ]
    doc.validate.none?(&.includes?("license")).should be_true
  end

  it "rejects a documentNamespace containing a '#' fragment delimiter" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test#fragment",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00Z",
        creators: ["Tool: test"]
      )
    )
    doc.validate.any?(&.includes?("'#' fragment delimiter")).should be_true
  end

  it "validates hasExtractedLicensingInfos entries" do
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
    doc.document_describes = ["SPDXRef-DOCUMENT"]
    doc.extracted_licensing_infos = [
      Spdx::ExtractedLicensingInfo.new(license_id: "not-a-license-ref", extracted_text: "text"),
      Spdx::ExtractedLicensingInfo.new(license_id: "LicenseRef-a", extracted_text: ""),
      Spdx::ExtractedLicensingInfo.new(license_id: "LicenseRef-a", extracted_text: "text"),
    ]

    errors = doc.validate
    errors.any?(&.includes?("licenseId must be of the form 'LicenseRef-[idstring]'")).should be_true
    errors.any?(&.includes?("extractedText is required")).should be_true
    errors.any?(&.includes?("duplicates 'LicenseRef-a'")).should be_true
  end

  it "accepts well-formed hasExtractedLicensingInfos entries" do
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
    doc.document_describes = ["SPDXRef-DOCUMENT"]
    doc.extracted_licensing_infos = [
      Spdx::ExtractedLicensingInfo.new(license_id: "LicenseRef-custom-1", extracted_text: "text"),
    ]
    doc.validate.none?(&.includes?("hasExtractedLicensingInfos")).should be_true
  end

  it "accepts a 'created' timestamp with fractional seconds" do
    doc = Spdx::SpdxDocument.new(
      spdx_version: "SPDX-2.3",
      data_license: "CC0-1.0",
      spdx_id: "SPDXRef-DOCUMENT",
      name: "Test",
      document_namespace: "https://example.org/test",
      creation_info: Spdx::CreationInfo.new(
        created: "2024-01-01T00:00:00.123Z",
        creators: ["Tool: test"]
      )
    )
    doc.validate.none?(&.includes?("ISO 8601")).should be_true
  end
end
