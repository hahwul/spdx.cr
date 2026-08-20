require "../../../spec_helper"

private def minimal_document
  Spdx::SpdxDocument.new(
    spdx_version: "SPDX-2.3",
    data_license: "CC0-1.0",
    spdx_id: "SPDXRef-DOCUMENT",
    name: "Example",
    document_namespace: "https://example.org/example",
    creation_info: Spdx::CreationInfo.new(
      created: "2024-01-01T00:00:00Z",
      creators: ["Tool: example"]
    )
  )
end

private def package_with(copyright : String = "Copyright 2024 ExampleOrg")
  Spdx::Package.new(
    spdx_id: "SPDXRef-Package",
    name: "Example Package",
    download_location: "NOASSERTION",
    license_concluded: "MIT",
    license_declared: "MIT",
    copyright_text: copyright
  )
end

describe Spdx::Format::TagValue::Generator do
  it "emits FilesAnalyzed when it is false" do
    doc = minimal_document
    doc.packages = [package_with.tap(&.files_analyzed=(false))]

    output = Spdx::Format::TagValue::Generator.generate(doc)
    output.should contain("FilesAnalyzed: false")

    # An omitted FilesAnalyzed defaults to true (SPDX 2.3 §7.8), so dropping
    # the `false` would silently flip the package's meaning.
    reparsed = Spdx::Format::TagValue::Parser.parse(output)
    reparsed.packages.not_nil![0].files_analyzed.should be_false
  end

  it "wraps a multi-line copyright text in a <text> block" do
    doc = minimal_document
    doc.packages = [
      package_with("Copyright 2024 A\nCopyright 2025 B").tap(&.files_analyzed=(false)),
    ]

    output = Spdx::Format::TagValue::Generator.generate(doc)
    output.should contain("PackageCopyrightText: <text>Copyright 2024 A\nCopyright 2025 B</text>")

    reparsed = Spdx::Format::TagValue::Parser.parse(output)
    reparsed.packages.not_nil![0].copyright_text.should eq("Copyright 2024 A\nCopyright 2025 B")
  end

  it "wraps a multi-line file copyright text in a <text> block" do
    doc = minimal_document
    file = Spdx::FileInfo.new(
      spdx_id: "SPDXRef-File1",
      file_name: "./main.cr",
      license_concluded: "MIT",
      copyright_text: "Copyright 2024 A\nCopyright 2025 B"
    )
    doc.files = [file]

    reparsed = Spdx::Format::TagValue::Parser.parse(
      Spdx::Format::TagValue::Generator.generate(doc)
    )
    reparsed.files.not_nil![0].copyright_text.should eq("Copyright 2024 A\nCopyright 2025 B")
  end

  it "wraps a multi-line snippet copyright text in a <text> block" do
    doc = minimal_document
    doc.snippets = [
      Spdx::Snippet.new(
        spdx_id: "SPDXRef-Snippet1",
        snippet_from_file: "SPDXRef-File1",
        ranges: [] of Spdx::SnippetRange,
        license_concluded: "MIT",
        copyright_text: "Copyright 2024 A\nCopyright 2025 B"
      ),
    ]

    reparsed = Spdx::Format::TagValue::Parser.parse(
      Spdx::Format::TagValue::Generator.generate(doc)
    )
    reparsed.snippets.not_nil![0].copyright_text.should eq("Copyright 2024 A\nCopyright 2025 B")
  end

  it "writes the checksum of an ExternalDocumentRef in the canonical spaced form" do
    doc = minimal_document
    doc.external_document_refs = [
      Spdx::ExternalDocumentRef.new(
        external_document_id: "DocumentRef-ext1",
        spdx_document: "https://example.org/ext1",
        checksum: Spdx::Checksum.new(Spdx::ChecksumAlgorithm::SHA1, "da39a3ee5e6b4b0d3255bfef95601890afd80709")
      ),
    ]

    output = Spdx::Format::TagValue::Generator.generate(doc)
    output.should contain(
      "ExternalDocumentRef: DocumentRef-ext1 https://example.org/ext1 SHA1: da39a3ee5e6b4b0d3255bfef95601890afd80709"
    )
  end

  it "refuses to emit a text value that closes its own <text> block" do
    doc = minimal_document
    doc.comment = "hello\n</text>\nDocumentName: Injected"

    expect_raises(Spdx::FormatError, /cannot be represented in tag-value format/) do
      Spdx::Format::TagValue::Generator.generate(doc)
    end
  end

  it "refuses to emit a line break in a single-line field" do
    doc = minimal_document
    doc.packages = [
      package_with.tap(&.name=("Evil\nSPDXID: SPDXRef-Injected")).tap(&.files_analyzed=(false)),
    ]

    expect_raises(Spdx::FormatError, /single-line tag-value field/) do
      Spdx::Format::TagValue::Generator.generate(doc)
    end
  end
end
