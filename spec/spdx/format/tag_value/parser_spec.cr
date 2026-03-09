require "../../../spec_helper"

describe Spdx::Format::TagValue::Parser do
  it "parses example Tag-Value file" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    doc.spdx_version.should eq("SPDX-2.3")
    doc.data_license.should eq("CC0-1.0")
    doc.name.should eq("Example")
    doc.document_namespace.should eq("https://example.org/example")
  end

  it "parses creation info" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    doc.creation_info.created.should eq("2024-01-01T00:00:00Z")
    doc.creation_info.creators.size.should eq(2)
    doc.creation_info.license_list_version.should eq("3.22")
  end

  it "parses packages" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    pkgs = doc.packages.not_nil!
    pkgs.size.should eq(1)
    pkgs[0].name.should eq("Example Package")
    pkgs[0].version_info.should eq("1.0.0")
    pkgs[0].license_concluded.should eq("Apache-2.0")
  end

  it "parses files" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    files = doc.files.not_nil!
    files.size.should eq(1)
    files[0].file_name.should eq("./src/main.cr")
    files[0].spdx_id.should eq("SPDXRef-File1")
  end

  it "parses relationships" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    rels = doc.relationships.not_nil!
    rels.size.should eq(2)
    rels[0].relationship_type.should eq(Spdx::RelationshipType::DESCRIBES)
    rels[0].spdx_element_id.should eq("SPDXRef-DOCUMENT")
  end

  it "parses extracted licensing infos with multiline text" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    infos = doc.extracted_licensing_infos.not_nil!
    infos.size.should eq(1)
    infos[0].license_id.should eq("LicenseRef-custom-1")
    infos[0].extracted_text.should contain("multiple lines")
  end

  it "parses snippets" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    snippets = doc.snippets.not_nil!
    snippets.size.should eq(1)
    snippets[0].spdx_id.should eq("SPDXRef-Snippet1")
    snippets[0].name.should eq("Main snippet")
  end

  it "parses external document refs" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    refs = doc.external_document_refs.not_nil!
    refs.size.should eq(1)
    refs[0].external_document_id.should eq("DocumentRef-ext1")
  end

  it "parses annotations" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    anns = doc.annotations.not_nil!
    anns.size.should eq(1)
    anns[0].annotation_type.should eq(Spdx::AnnotationType::REVIEW)
    anns[0].annotator.should eq("Person: Jane Doe (jane@example.org)")
  end

  it "generates Tag-Value from parsed document" do
    doc = Spdx::Format::TagValue::Parser.parse_file("spec/fixtures/example.spdx")
    output = Spdx::Format::TagValue::Generator.generate(doc)
    output.should contain("SPDXVersion: SPDX-2.3")
    output.should contain("PackageName: Example Package")
    output.should contain("Relationship: SPDXRef-DOCUMENT DESCRIBES SPDXRef-Package")
  end
end
