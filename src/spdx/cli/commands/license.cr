module Spdx
  module CLI
    module Commands
      module License
        extend self

        def list(osi_only : Bool = false, fsf_only : Bool = false)
          licenses = if osi_only
                       LicenseList.osi_approved
                     elsif fsf_only
                       LicenseList.fsf_libre
                     else
                       LicenseList.licenses
                     end

          licenses = licenses.reject(&.deprecated?)

          puts "%-30s %s" % {"ID", "Name"}
          puts "-" * 80
          licenses.each do |lic|
            flags = String.build do |s|
              s << " [OSI]" if lic.osi_approved?
              s << " [FSF]" if lic.fsf_libre?
            end
            puts "%-30s %s%s" % {lic.id, lic.name, flags}
          end
          puts "\nTotal: #{licenses.size} licenses"
        end

        def info(id : String)
          lic = LicenseList.find_license(id)
          puts "ID:           #{lic.id}"
          puts "Name:         #{lic.name}"
          puts "OSI Approved: #{lic.osi_approved? ? "yes" : "no"}"
          puts "FSF Libre:    #{lic.fsf_libre? ? "yes" : "no"}"
          puts "Deprecated:   #{lic.deprecated? ? "yes" : "no"}"
        rescue ex : UnknownLicenseError
          STDERR.puts "Error: #{ex.message}"
          # Try searching
          results = LicenseList.search(id)
          if results.any?
            STDERR.puts "\nDid you mean:"
            results.first(5).each { |r| STDERR.puts "  #{r.id} - #{r.name}" }
          end
          exit 1
        end

        def search(query : String)
          results = LicenseList.search(query)
          if results.empty?
            puts "No licenses found matching '#{query}'"
          else
            puts "%-30s %s" % {"ID", "Name"}
            puts "-" * 80
            results.each do |lic|
              flags = String.build do |s|
                s << " [OSI]" if lic.osi_approved?
                s << " [FSF]" if lic.fsf_libre?
                s << " [DEPRECATED]" if lic.deprecated?
              end
              puts "%-30s %s%s" % {lic.id, lic.name, flags}
            end
            puts "\nFound: #{results.size} licenses"
          end
        end
      end
    end
  end
end
