require "../../spec_helper"

describe Spdx::Expression::Tokenizer do
  it "tokenizes a simple license" do
    tokens = Spdx::Expression::Tokenizer.new("MIT").tokenize
    tokens.size.should eq(2) # MIT + EOF
    tokens[0].type.should eq(Spdx::Expression::TokenType::LicenseId)
    tokens[0].value.should eq("MIT")
  end

  it "tokenizes AND expression" do
    tokens = Spdx::Expression::Tokenizer.new("MIT AND Apache-2.0").tokenize
    tokens.size.should eq(4) # MIT AND Apache-2.0 EOF
    tokens[0].type.should eq(Spdx::Expression::TokenType::LicenseId)
    tokens[1].type.should eq(Spdx::Expression::TokenType::And)
    tokens[2].type.should eq(Spdx::Expression::TokenType::LicenseId)
  end

  it "tokenizes OR expression" do
    tokens = Spdx::Expression::Tokenizer.new("MIT OR GPL-2.0-only").tokenize
    tokens[1].type.should eq(Spdx::Expression::TokenType::Or)
  end

  it "tokenizes WITH expression" do
    tokens = Spdx::Expression::Tokenizer.new("GPL-2.0-only WITH Classpath-exception-2.0").tokenize
    tokens[1].type.should eq(Spdx::Expression::TokenType::With)
  end

  it "tokenizes or-later (+)" do
    tokens = Spdx::Expression::Tokenizer.new("GPL-2.0+").tokenize
    tokens[0].type.should eq(Spdx::Expression::TokenType::LicenseId)
    tokens[1].type.should eq(Spdx::Expression::TokenType::Plus)
  end

  it "tokenizes parentheses" do
    tokens = Spdx::Expression::Tokenizer.new("(MIT OR Apache-2.0)").tokenize
    tokens[0].type.should eq(Spdx::Expression::TokenType::LParen)
    tokens[4].type.should eq(Spdx::Expression::TokenType::RParen)
  end

  it "tokenizes LicenseRef" do
    tokens = Spdx::Expression::Tokenizer.new("LicenseRef-custom-1").tokenize
    tokens[0].type.should eq(Spdx::Expression::TokenType::LicenseRef)
    tokens[0].value.should eq("LicenseRef-custom-1")
  end

  it "tokenizes DocumentRef" do
    tokens = Spdx::Expression::Tokenizer.new("DocumentRef-ext1:LicenseRef-custom-1").tokenize
    tokens[0].type.should eq(Spdx::Expression::TokenType::DocumentRef)
    tokens[1].type.should eq(Spdx::Expression::TokenType::Colon)
    tokens[2].type.should eq(Spdx::Expression::TokenType::LicenseRef)
  end

  it "handles case-insensitive operators" do
    tokens = Spdx::Expression::Tokenizer.new("MIT and Apache-2.0").tokenize
    tokens[1].type.should eq(Spdx::Expression::TokenType::And)
  end
end
