require "../../spec_helper"

describe Spdx::RelationshipType do
  describe ".from_string" do
    it "parses a known relationship type" do
      Spdx::RelationshipType.from_string("DESCRIBES").should eq(Spdx::RelationshipType::DESCRIBES)
    end

    it "normalizes dashes to underscores" do
      Spdx::RelationshipType.from_string("DEPENDS-ON").should eq(Spdx::RelationshipType::DEPENDS_ON)
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
