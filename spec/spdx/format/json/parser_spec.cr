require "../../../spec_helper"

describe Spdx::Format::Json::Parser do
  it "parses example JSON file" do
    doc = Spdx::Format::Json::Parser.parse_file("spec/fixtures/example.spdx.json")
    doc.spdx_version.should eq("SPDX-2.3")
    doc.data_license.should eq("CC0-1.0")
    doc.name.should eq("Example")
    doc.valid?.should be_true
  end

  it "parses packages" do
    doc = Spdx::Format::Json::Parser.parse_file("spec/fixtures/example.spdx.json")
    pkgs = doc.packages.not_nil!
    pkgs.size.should eq(1)
    pkgs[0].name.should eq("Example Package")
    pkgs[0].version_info.should eq("1.0.0")
    pkgs[0].license_concluded.should eq("Apache-2.0")
  end

  it "parses files" do
    doc = Spdx::Format::Json::Parser.parse_file("spec/fixtures/example.spdx.json")
    files = doc.files.not_nil!
    files.size.should eq(1)
    files[0].file_name.should eq("./src/main.cr")
  end

  it "parses relationships" do
    doc = Spdx::Format::Json::Parser.parse_file("spec/fixtures/example.spdx.json")
    rels = doc.relationships.not_nil!
    rels.size.should eq(2)
    rels[0].relationship_type.should eq(Spdx::RelationshipType::DESCRIBES)
  end

  it "parses annotations" do
    doc = Spdx::Format::Json::Parser.parse_file("spec/fixtures/example.spdx.json")
    anns = doc.annotations.not_nil!
    anns.size.should eq(1)
    anns[0].annotation_type.should eq(Spdx::AnnotationType::REVIEW)
  end

  it "parses extracted licensing infos" do
    doc = Spdx::Format::Json::Parser.parse_file("spec/fixtures/example.spdx.json")
    infos = doc.extracted_licensing_infos.not_nil!
    infos.size.should eq(1)
    infos[0].license_id.should eq("LicenseRef-custom-1")
  end

  it "raises on invalid JSON" do
    expect_raises(Spdx::FormatError) do
      Spdx::Format::Json::Parser.parse("not json")
    end
  end

  it "round-trips JSON" do
    doc = Spdx::Format::Json::Parser.parse_file("spec/fixtures/example.spdx.json")
    json = Spdx::Format::Json::Generator.generate(doc)
    doc2 = Spdx::Format::Json::Parser.parse(json)
    doc2.spdx_version.should eq(doc.spdx_version)
    doc2.name.should eq(doc.name)
    doc2.packages.not_nil!.size.should eq(doc.packages.not_nil!.size)
  end
end
