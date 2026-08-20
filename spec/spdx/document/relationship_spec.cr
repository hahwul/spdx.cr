require "../../spec_helper"

describe Spdx::RelationshipType do
  describe ".from_string" do
    it "parses a known relationship type" do
      Spdx::RelationshipType.from_string("DESCRIBES").should eq(Spdx::RelationshipType::DESCRIBES)
    end

    it "normalizes dashes to underscores" do
      Spdx::RelationshipType.from_string("DEPENDS-ON").should eq(Spdx::RelationshipType::DEPENDS_ON)
    end

    it "parses every relationship type defined by SPDX 2.3" do
      # SPDX 2.3 clause 11.1, Table 68 (45 values).
      %w[
        DESCRIBES DESCRIBED_BY CONTAINS CONTAINED_BY DEPENDS_ON DEPENDENCY_OF
        DEPENDENCY_MANIFEST_OF BUILD_DEPENDENCY_OF DEV_DEPENDENCY_OF
        OPTIONAL_DEPENDENCY_OF PROVIDED_DEPENDENCY_OF TEST_DEPENDENCY_OF
        RUNTIME_DEPENDENCY_OF EXAMPLE_OF GENERATES GENERATED_FROM ANCESTOR_OF
        DESCENDANT_OF VARIANT_OF DISTRIBUTION_ARTIFACT PATCH_FOR PATCH_APPLIED
        COPY_OF FILE_ADDED FILE_DELETED FILE_MODIFIED EXPANDED_FROM_ARCHIVE
        DYNAMIC_LINK STATIC_LINK DATA_FILE_OF TEST_CASE_OF BUILD_TOOL_OF
        DEV_TOOL_OF TEST_OF TEST_TOOL_OF DOCUMENTATION_OF
        OPTIONAL_COMPONENT_OF METAFILE_OF PACKAGE_OF AMENDS PREREQUISITE_FOR
        HAS_PREREQUISITE REQUIREMENT_DESCRIPTION_FOR SPECIFICATION_FOR OTHER
      ].each do |name|
        Spdx::RelationshipType.from_string(name).to_s.should eq(name)
      end
    end

    it "raises FormatError (not ArgumentError) on an unknown relationship type" do
      expect_raises(Spdx::FormatError, "Unknown relationship type: INVALID_TYPE") do
        Spdx::RelationshipType.from_string("INVALID_TYPE")
      end
    end
  end
end

describe Spdx::Format::TagValue::Parser do
  it "raises FormatError when a document contains an invalid relationship type" do
    input = <<-SPDX
      SPDXVersion: SPDX-2.3
      DataLicense: CC0-1.0
      SPDXID: SPDXRef-DOCUMENT
      DocumentName: Example
      DocumentNamespace: https://example.org/example
      Creator: Tool: example
      Created: 2024-01-01T00:00:00Z
      Relationship: SPDXRef-A INVALID_TYPE SPDXRef-B
      SPDX

    expect_raises(Spdx::FormatError, "Unknown relationship type: INVALID_TYPE") do
      Spdx::Format::TagValue::Parser.parse(input)
    end
  end
end
