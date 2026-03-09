require "option_parser"

module Spdx
  module CLI
    class App
      @command : String = ""
      @subcommand : String = ""
      @args : Array(String) = [] of String
      @format : String = "json"
      @osi_only : Bool = false
      @fsf_only : Bool = false

      def run(argv : Array(String) = ARGV)
        if argv.empty?
          print_help
          return
        end

        @command = argv[0]

        case @command
        when "expression"
          handle_expression(argv[1..])
        when "license"
          handle_license(argv[1..])
        when "validate"
          handle_validate(argv[1..])
        when "convert"
          handle_convert(argv[1..])
        when "version", "--version", "-v"
          puts "spdx #{VERSION}"
        when "help", "--help", "-h"
          print_help
        else
          STDERR.puts "Unknown command: #{@command}"
          STDERR.puts "Run 'spdx help' for usage"
          exit 1
        end
      end

      private def handle_expression(args : Array(String))
        if args.empty?
          print_expression_help
          return
        end

        @subcommand = args[0]
        case @subcommand
        when "parse"
          if args.size < 2
            STDERR.puts "Usage: spdx expression parse <expression>"
            exit 1
          end
          Commands::Expression.parse_expression(args[1..].join(" "))
        when "validate"
          if args.size < 2
            STDERR.puts "Usage: spdx expression validate <expression>"
            exit 1
          end
          Commands::Expression.validate_expression(args[1..].join(" "))
        else
          STDERR.puts "Unknown subcommand: #{@subcommand}"
          print_expression_help
          exit 1
        end
      end

      private def handle_license(args : Array(String))
        if args.empty?
          print_license_help
          return
        end

        @subcommand = args[0]
        remaining = args[1..]

        case @subcommand
        when "list"
          osi = false
          fsf = false
          remaining.each do |arg|
            case arg
            when "--osi" then osi = true
            when "--fsf" then fsf = true
            end
          end
          Commands::License.list(osi_only: osi, fsf_only: fsf)
        when "info"
          if remaining.empty?
            STDERR.puts "Usage: spdx license info <license-id>"
            exit 1
          end
          Commands::License.info(remaining[0])
        when "search"
          if remaining.empty?
            STDERR.puts "Usage: spdx license search <query>"
            exit 1
          end
          Commands::License.search(remaining.join(" "))
        else
          STDERR.puts "Unknown subcommand: #{@subcommand}"
          print_license_help
          exit 1
        end
      end

      private def handle_validate(args : Array(String))
        if args.empty?
          STDERR.puts "Usage: spdx validate <file>"
          exit 1
        end
        Commands::Validate.run(args[0])
      end

      private def handle_convert(args : Array(String))
        file = ""
        format = ""

        i = 0
        while i < args.size
          case args[i]
          when "--format", "-f"
            i += 1
            format = args[i]? || ""
          else
            file = args[i] if file.empty?
          end
          i += 1
        end

        if file.empty?
          STDERR.puts "Usage: spdx convert <file> --format json|tv"
          exit 1
        end

        if format.empty?
          STDERR.puts "Error: --format is required (json or tv)"
          exit 1
        end

        Commands::Convert.run(file, format)
      end

      private def print_help
        puts "spdx - SPDX toolkit for Crystal"
        puts ""
        puts "Usage: spdx <command> [options]"
        puts ""
        puts "Commands:"
        puts "  expression    Parse and validate SPDX license expressions"
        puts "  license       Query SPDX license list"
        puts "  validate      Validate SPDX documents"
        puts "  convert       Convert between SPDX formats"
        puts "  version       Show version"
        puts "  help          Show this help"
        puts ""
        puts "Run 'spdx <command>' for more information on a command."
      end

      private def print_expression_help
        puts "Usage: spdx expression <subcommand> <expression>"
        puts ""
        puts "Subcommands:"
        puts "  parse       Parse and display expression AST"
        puts "  validate    Validate expression against license list"
      end

      private def print_license_help
        puts "Usage: spdx license <subcommand> [options]"
        puts ""
        puts "Subcommands:"
        puts "  list [--osi] [--fsf]    List licenses"
        puts "  info <id>               Show license details"
        puts "  search <query>          Search licenses"
      end
    end
  end
end
