require "json"

module Spdx
  enum ChecksumAlgorithm
    SHA1
    SHA224
    SHA256
    SHA384
    SHA512
    SHA3_256
    SHA3_384
    SHA3_512
    BLAKE2b_256
    BLAKE2b_384
    BLAKE2b_512
    BLAKE3
    MD2
    MD4
    MD5
    MD6
    ADLER32

    def to_s : String
      case self
      when SHA1        then "SHA1"
      when SHA224      then "SHA224"
      when SHA256      then "SHA256"
      when SHA384      then "SHA384"
      when SHA512      then "SHA512"
      when SHA3_256    then "SHA3-256"
      when SHA3_384    then "SHA3-384"
      when SHA3_512    then "SHA3-512"
      when BLAKE2b_256 then "BLAKE2b-256"
      when BLAKE2b_384 then "BLAKE2b-384"
      when BLAKE2b_512 then "BLAKE2b-512"
      when BLAKE3      then "BLAKE3"
      when MD2         then "MD2"
      when MD4         then "MD4"
      when MD5         then "MD5"
      when MD6         then "MD6"
      when ADLER32     then "ADLER32"
      else                  super
      end
    end

    def self.from_string(s : String) : self
      case s.upcase
      when "SHA1"        then SHA1
      when "SHA224"      then SHA224
      when "SHA256"      then SHA256
      when "SHA384"      then SHA384
      when "SHA512"      then SHA512
      when "SHA3-256"    then SHA3_256
      when "SHA3-384"    then SHA3_384
      when "SHA3-512"    then SHA3_512
      when "BLAKE2B-256" then BLAKE2b_256
      when "BLAKE2B-384" then BLAKE2b_384
      when "BLAKE2B-512" then BLAKE2b_512
      when "BLAKE3"      then BLAKE3
      when "MD2"         then MD2
      when "MD4"         then MD4
      when "MD5"         then MD5
      when "MD6"         then MD6
      when "ADLER32"     then ADLER32
      else
        raise FormatError.new("Unknown checksum algorithm: #{s}")
      end
    end

    def to_json(json : JSON::Builder)
      json.string(to_s)
    end

    def self.new(pull : JSON::PullParser) : self
      from_string(pull.read_string)
    end
  end

  class Checksum
    include JSON::Serializable

    @[JSON::Field(key: "algorithm")]
    property algorithm : ChecksumAlgorithm

    @[JSON::Field(key: "checksumValue")]
    property value : String

    def initialize(@algorithm : ChecksumAlgorithm, @value : String)
    end
  end
end
