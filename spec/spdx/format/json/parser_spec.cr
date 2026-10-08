require "../../../spec_helper"

describe Spdx::Format::Json::Parser do
  it "parses example JSON file" do
    doc = Spdx::Format::Json::Parser.parse_file("spec/fixtures/example.spdx.json")
    doc.spdx_version.should eq("SPDX-2.3")
    doc.data_license.should eq("CC0-1.0")
    doc.name.should eq("Example")
    doc.valid?.should be_true
  end

  it "is reachable via the Spdx::Format::JSON alias (stdlib-style casing)" do
    Spdx::Format::JSON::Parser.should eq(Spdx::Format::Json::Parser)
    Spdx::Format::JSON::Generator.should eq(Spdx::Format::Json::Generator)
    doc = Spdx::Format::JSON::Parser.parse_file("spec/fixtures/example.spdx.json")
    doc.name.should eq("Example")
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
    anns = doc.packages.not_nil![0].annotations.not_nil!
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

  it "raises FormatError (not ArgumentError) on an unknown annotationType" do
    input = %({"spdxVersion":"SPDX-2.3","dataLicense":"CC0-1.0","SPDXID":"SPDXRef-DOCUMENT",) +
            %("name":"x","documentNamespace":"https://example.org/x",) +
            %("creationInfo":{"created":"2024-01-01T00:00:00Z","creators":["Tool: t"]},) +
            %("annotations":[{"annotationDate":"2024-01-01T00:00:00Z","annotationType":"BOGUS",) +
            %("annotator":"Person: a","comment":"c"}]})

    expect_raises(Spdx::FormatError, "Unknown annotation type: BOGUS") do
      Spdx::Format::Json::Parser.parse(input)
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

  it "parses elements that omit licenseConcluded, licenseDeclared and copyrightText" do
    # SPDX 2.3 §7.13/§7.15/§7.17/§8.5/§8.8/§9.6/§9.8: cardinality 0..1; the
    # official SPDXJSONExample-v2.3 has such a package.
    input = %({"spdxVersion":"SPDX-2.3","dataLicense":"CC0-1.0","SPDXID":"SPDXRef-DOCUMENT",) +
            %("name":"x","documentNamespace":"https://example.org/x",) +
            %("creationInfo":{"created":"2024-01-01T00:00:00Z","creators":["Tool: t"]},) +
            %("documentDescribes":["SPDXRef-P"],) +
            %("packages":[{"SPDXID":"SPDXRef-P","name":"p","downloadLocation":"NOASSERTION","filesAnalyzed":false}],) +
            %("files":[{"SPDXID":"SPDXRef-F","fileName":"./f","checksums":[{"algorithm":"SHA1","checksumValue":"d6a770ba38583ed4bb4525bd96e50461655d2758"}]}],) +
            %("snippets":[{"SPDXID":"SPDXRef-S","snippetFromFile":"SPDXRef-F","ranges":[{"startPointer":{"reference":"SPDXRef-F","offset":1},"endPointer":{"reference":"SPDXRef-F","offset":2}}]}]})

    doc = Spdx::Format::Json::Parser.parse(input)
    pkg = doc.packages.not_nil![0]
    pkg.license_concluded.should be_nil
    pkg.license_declared.should be_nil
    pkg.copyright_text.should be_nil
    doc.files.not_nil![0].license_concluded.should be_nil
    doc.snippets.not_nil![0].copyright_text.should be_nil
    doc.validate.should be_empty

    json = Spdx::Format::Json::Generator.generate(doc)
    json.should_not contain("licenseConcluded")
    json.should_not contain("copyrightText")
  end

  it "keeps element annotations, hasFiles and file licenseComments" do
    input = %({"spdxVersion":"SPDX-2.3","dataLicense":"CC0-1.0","SPDXID":"SPDXRef-DOCUMENT",) +
            %("name":"x","documentNamespace":"https://example.org/x",) +
            %("creationInfo":{"created":"2024-01-01T00:00:00Z","creators":["Tool: t"]},) +
            %("packages":[{"SPDXID":"SPDXRef-P","name":"p","downloadLocation":"NOASSERTION","hasFiles":["SPDXRef-F"],) +
            %("annotations":[{"annotationDate":"2024-01-01T00:00:00Z","annotationType":"OTHER","annotator":"Person: a","comment":"pkg"}]}],) +
            %("files":[{"SPDXID":"SPDXRef-F","fileName":"./f","licenseComments":"why",) +
            %("checksums":[{"algorithm":"SHA1","checksumValue":"d6a770ba38583ed4bb4525bd96e50461655d2758"}],) +
            %("annotations":[{"annotationDate":"2024-01-01T00:00:00Z","annotationType":"REVIEW","annotator":"Person: b","comment":"file"}]}]})

    doc = Spdx::Format::Json::Parser.parse(Spdx::Format::Json::Generator.generate(Spdx::Format::Json::Parser.parse(input)))
    pkg = doc.packages.not_nil![0]
    pkg.has_files.should eq(["SPDXRef-F"])
    pkg.annotations.not_nil![0].comment.should eq("pkg")
    file = doc.files.not_nil![0]
    file.license_comments.should eq("why")
    file.annotations.not_nil![0].comment.should eq("file")
  end

  it "nests a legacy document-level spdxElementId annotation under its element" do
    # The SPDX 2.3 JSON schema has no annotation `spdxElementId`; element
    # annotations live in the element's own `annotations` array.
    doc = Spdx::Format::Json::Parser.parse_file("spec/fixtures/example.spdx.json")
    doc.annotations.should be_nil
    doc.packages.not_nil![0].annotations.not_nil![0].spdx_element_id.should eq("SPDXRef-Package")

    json = JSON.parse(Spdx::Format::Json::Generator.generate(doc))
    json.as_h.has_key?("annotations").should be_false
    anns = json["packages"][0]["annotations"].as_a
    anns.size.should eq(1)
    anns[0].as_h.has_key?("spdxElementId").should be_false
  end
end
