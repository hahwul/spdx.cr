require "../../spec_helper"

describe Spdx::Expression::Formatter do
  it "formats a simple license" do
    ast = Spdx::Expression::Parser.parse("MIT")
    Spdx::Expression::Formatter.format(ast).should eq("MIT")
  end

  it "formats AND expression" do
    ast = Spdx::Expression::Parser.parse("MIT AND Apache-2.0")
    Spdx::Expression::Formatter.format(ast).should eq("MIT AND Apache-2.0")
  end

  it "formats OR expression" do
    ast = Spdx::Expression::Parser.parse("MIT OR Apache-2.0")
    Spdx::Expression::Formatter.format(ast).should eq("MIT OR Apache-2.0")
  end

  it "formats WITH expression" do
    ast = Spdx::Expression::Parser.parse("GPL-2.0-only WITH Classpath-exception-2.0")
    Spdx::Expression::Formatter.format(ast).should eq("GPL-2.0-only WITH Classpath-exception-2.0")
  end

  it "formats or-later" do
    ast = Spdx::Expression::Parser.parse("GPL-2.0+")
    Spdx::Expression::Formatter.format(ast).should eq("GPL-2.0+")
  end

  it "normalizes expression" do
    result = Spdx::Expression::Formatter.normalize("MIT   AND   Apache-2.0")
    result.should eq("MIT AND Apache-2.0")
  end

  it "formats DocumentRef:LicenseRef" do
    ast = Spdx::Expression::Parser.parse("DocumentRef-ext1:LicenseRef-custom-1")
    Spdx::Expression::Formatter.format(ast).should eq("DocumentRef-ext1:LicenseRef-custom-1")
  end
end
