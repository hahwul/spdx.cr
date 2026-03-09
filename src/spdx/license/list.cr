require "./data"

module Spdx
  module LicenseList
    extend self

    @@licenses : Array(License)?
    @@exceptions : Array(LicenseException)?
    @@license_map : Hash(String, License)?
    @@exception_map : Hash(String, LicenseException)?

    def licenses : Array(License)
      @@licenses ||= LICENSE_DATA.map do |d|
        License.new(
          id: d[:id],
          name: d[:name],
          osi_approved: d[:osi_approved],
          fsf_libre: d[:fsf_libre],
          deprecated: d[:deprecated]
        )
      end
    end

    def exceptions : Array(LicenseException)
      @@exceptions ||= EXCEPTION_DATA.map do |d|
        LicenseException.new(
          id: d[:id],
          name: d[:name],
          deprecated: d[:deprecated]
        )
      end
    end

    private def license_map : Hash(String, License)
      @@license_map ||= licenses.each_with_object({} of String => License) do |lic, map|
        map[lic.id.downcase] = lic
      end
    end

    private def exception_map : Hash(String, LicenseException)
      @@exception_map ||= exceptions.each_with_object({} of String => LicenseException) do |exc, map|
        map[exc.id.downcase] = exc
      end
    end

    def find_license(id : String) : License
      license_map[id.downcase]? || raise UnknownLicenseError.new(id)
    end

    def license?(id : String) : Bool
      license_map.has_key?(id.downcase)
    end

    def find_exception(id : String) : LicenseException
      exception_map[id.downcase]? || raise UnknownExceptionError.new(id)
    end

    def exception?(id : String) : Bool
      exception_map.has_key?(id.downcase)
    end

    def search(query : String) : Array(License)
      q = query.downcase
      licenses.select do |lic|
        lic.id.downcase.includes?(q) || lic.name.downcase.includes?(q)
      end
    end

    def search_exceptions(query : String) : Array(LicenseException)
      q = query.downcase
      exceptions.select do |exc|
        exc.id.downcase.includes?(q) || exc.name.downcase.includes?(q)
      end
    end

    def osi_approved : Array(License)
      licenses.select(&.osi_approved?)
    end

    def fsf_libre : Array(License)
      licenses.select(&.fsf_libre?)
    end
  end
end
