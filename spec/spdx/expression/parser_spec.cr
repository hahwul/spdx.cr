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

  it "raises on excessive parenthesis nesting instead of overflowing the stack" do
    # Without a depth cap this exhausts the call stack as parse_or →
    # parse_and → parse_with → parse_primary → parse_or recurses on each
    # nested '('.
    nesting = 10_000
    expr = ("(" * nesting) + "MIT" + (")" * nesting)
    expect_raises(Spdx::ParseError, /maximum depth/) do
      Spdx::Expression::Parser.parse(expr)
    end
  end

  it "still parses expressions just under the depth cap" do
    nesting = Spdx::Expression::Parser::MAX_DEPTH - 1
    expr = ("(" * nesting) + "MIT" + (")" * nesting)
    Spdx::Expression::Parser.parse(expr).should_not be_nil
  end

  it "parses '+' only when adjacent to the license id" do
    node = Spdx::Expression::Parser.parse("MIT+")
    node.as(Spdx::Expression::LicenseNode).or_later?.should be_true
  end

  it "rejects '+' separated from the license id by whitespace" do
    expect_raises(Spdx::ParseError, /must immediately follow/) do
      Spdx::Expression::Parser.parse("MIT +")
    end
  end

  it "rejects a standalone '+'" do
    expect_raises(Spdx::ParseError) do
      Spdx::Expression::Parser.parse("+")
    end
  end

  it "parses NONE as a reserved value" do
    node = Spdx::Expression::Parser.parse("NONE")
    node.should be_a(Spdx::Expression::ReservedNode)
    node.as(Spdx::Expression::ReservedNode).none?.should be_true
    node.to_s.should eq("NONE")
  end

  it "parses NOASSERTION as a reserved value" do
    node = Spdx::Expression::Parser.parse("NOASSERTION")
    node.should be_a(Spdx::Expression::ReservedNode)
    node.as(Spdx::Expression::ReservedNode).noassertion?.should be_true
  end

  it "rejects NONE combined with other licenses" do
    expect_raises(Spdx::ParseError, /cannot be combined/) do
      Spdx::Expression::Parser.parse("MIT AND NONE")
    end
  end
end
