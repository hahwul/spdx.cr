require "../../spec_helper"

describe Spdx::Expression::Parser do
  it "parses a simple license" do
    node = Spdx::Expression::Parser.parse("MIT")
    node.should be_a(Spdx::Expression::LicenseNode)
    node.as(Spdx::Expression::LicenseNode).id.should eq("MIT")
  end

  it "parses or-later" do
    node = Spdx::Expression::Parser.parse("GPL-2.0+")
    node.should be_a(Spdx::Expression::LicenseNode)
    node.as(Spdx::Expression::LicenseNode).or_later?.should be_true
  end

  it "parses AND expression" do
    node = Spdx::Expression::Parser.parse("MIT AND Apache-2.0")
    node.should be_a(Spdx::Expression::CompoundNode)
    compound = node.as(Spdx::Expression::CompoundNode)
    compound.operator.should eq(Spdx::Expression::CompoundNode::Operator::AND)
    compound.left.to_s.should eq("MIT")
    compound.right.to_s.should eq("Apache-2.0")
  end

  it "parses OR expression" do
    node = Spdx::Expression::Parser.parse("MIT OR Apache-2.0")
    node.should be_a(Spdx::Expression::CompoundNode)
    compound = node.as(Spdx::Expression::CompoundNode)
    compound.operator.should eq(Spdx::Expression::CompoundNode::Operator::OR)
  end

  it "parses WITH expression" do
    node = Spdx::Expression::Parser.parse("GPL-2.0-only WITH Classpath-exception-2.0")
    node.should be_a(Spdx::Expression::WithExceptionNode)
    with_node = node.as(Spdx::Expression::WithExceptionNode)
    with_node.exception.should eq("Classpath-exception-2.0")
  end

  it "respects operator precedence: AND binds tighter than OR" do
    node = Spdx::Expression::Parser.parse("MIT OR Apache-2.0 AND GPL-2.0-only")
    node.should be_a(Spdx::Expression::CompoundNode)
    compound = node.as(Spdx::Expression::CompoundNode)
    compound.operator.should eq(Spdx::Expression::CompoundNode::Operator::OR)
    compound.left.to_s.should eq("MIT")
    compound.right.should be_a(Spdx::Expression::CompoundNode)
  end

  it "handles parentheses" do
    node = Spdx::Expression::Parser.parse("(MIT OR Apache-2.0) AND GPL-2.0-only")
    compound = node.as(Spdx::Expression::CompoundNode)
    compound.operator.should eq(Spdx::Expression::CompoundNode::Operator::AND)
    compound.left.should be_a(Spdx::Expression::CompoundNode)
    compound.right.to_s.should eq("GPL-2.0-only")
  end

  it "parses LicenseRef" do
    node = Spdx::Expression::Parser.parse("LicenseRef-custom-1")
    node.should be_a(Spdx::Expression::LicenseRefNode)
    node.as(Spdx::Expression::LicenseRefNode).license_ref.should eq("LicenseRef-custom-1")
  end

  it "parses DocumentRef:LicenseRef" do
    node = Spdx::Expression::Parser.parse("DocumentRef-ext1:LicenseRef-custom-1")
    node.should be_a(Spdx::Expression::LicenseRefNode)
    ref = node.as(Spdx::Expression::LicenseRefNode)
    ref.document_ref.should eq("DocumentRef-ext1")
    ref.license_ref.should eq("LicenseRef-custom-1")
  end

  it "parses complex nested expressions" do
    expr = "(MIT OR Apache-2.0) AND (GPL-2.0-only WITH Classpath-exception-2.0 OR BSD-3-Clause)"
    node = Spdx::Expression::Parser.parse(expr)
    node.should be_a(Spdx::Expression::CompoundNode)
  end

  it "raises on empty expression" do
    expect_raises(Spdx::ParseError) do
      Spdx::Expression::Parser.parse("")
    end
  end

  it "raises on invalid expression" do
    expect_raises(Spdx::ParseError) do
      Spdx::Expression::Parser.parse("AND")
    end
  end

  it "raises on unbalanced parentheses" do
    expect_raises(Spdx::ParseError) do
      Spdx::Expression::Parser.parse("(MIT AND Apache-2.0")
    end
  end

  it "raises on missing operand" do
    expect_raises(Spdx::ParseError) do
      Spdx::Expression::Parser.parse("MIT AND")
    end
  end
end
