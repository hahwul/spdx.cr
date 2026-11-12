require "../../spec_helper"
require "../../../src/spdx/cli/commands/load_document"
require "../../../src/spdx/cli/commands/license"

describe Spdx::CLI::Commands do
  it "raises DocumentError for a path it cannot read, not IO::Error" do
    expect_raises(Spdx::DocumentError, /Cannot read/) do
      Spdx::CLI::Commands.load_document(Dir.tempdir)
    end
  end

  it "detects JSON that begins with white space" do
    path = File.tempname("spdx", ".spdx")
    File.write(path, "\n  " + File.read("spec/fixtures/example.spdx.json"))
    begin
      Spdx::CLI::Commands.load_document(path).name.should eq(Spdx::Format::Json::Parser.parse_file("spec/fixtures/example.spdx.json").name)
    ensure
      File.delete(path)
    end
  end

  it "applies --osi and --fsf together" do
    both = Spdx::CLI::Commands::License.filter(osi_only: true, fsf_only: true)
    both.should_not be_empty
    both.all? { |l| l.osi_approved? && l.fsf_libre? && !l.deprecated? }.should be_true
    both.size.should be < Spdx::CLI::Commands::License.filter(osi_only: true).size
  end
end
