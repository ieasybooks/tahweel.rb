# frozen_string_literal: true

require "optparse"

module Tahweel
  module CLI
    # Parses command-line arguments for the Tahweel CLI.
    class Options
      # Parses the command-line arguments.
      #
      # @param args [Array<String>] The command-line arguments.
      # @return [Hash] The parsed options.
      def self.parse(args)
        options = default_options
        parser = OptionParser.new { configure_parser(_1, options) }

        begin
          parser.parse!(args)
        rescue OptionParser::InvalidOption => e
          abort "Error: #{e.message}"
        end

        validate_args!(args, parser)
        options
      end

      def self.default_options
        {
          dpi: 150,
          processor: :google_drive,
          page_concurrency: Tahweel::Converter::DEFAULT_CONCURRENCY,
          file_concurrency: 1,
          output: nil,
          formats: [:txt],
          page_separator: Tahweel::Writers::Txt::PAGE_SEPARATOR
        }
      end

      def self.configure_parser(opts, options) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
        opts.banner = "Usage: tahweel <file_path> [options]"

        opts.on(
          "-e", "--extensions EXTENSIONS", Array,
          "Comma-separated list of file extensions to process " \
          "(default: #{Tahweel::CLI::FileCollector::SUPPORTED_EXTENSIONS.join(", ")})"
        ) do |e|
          options[:extensions] = e
        end

        opts.on("--dpi DPI", Integer, "DPI for PDF to Image conversion (default: 150)") do |d|
          options[:dpi] = d
        end

        opts.on(
          "-p", "--processor PROCESSOR", Tahweel::Ocr::AVAILABLE_PROCESSORS,
          "OCR processor to use (default: google_drive). Available: #{Tahweel::Ocr::AVAILABLE_PROCESSORS.join(", ")}"
        ) do |p|
          options[:processor] = p
        end

        opts.on("--page-concurrency N", Integer, "Max concurrent OCR operations (default: 12)") do |n|
          abort "Error: page-concurrency must be a positive integer" if n < 1

          options[:page_concurrency] = n
        end

        opts.on(
          "--file-concurrency N", Integer,
          "Max number of files to process in parallel (default: 1)"
        ) do |n|
          abort "Error: file-concurrency must be a positive integer" if n < 1

          options[:file_concurrency] = n
        end

        opts.on(
          "-f", "--formats FORMATS", Array,
          "Output formats (comma-separated, default: txt). Available: #{Tahweel::Writer::AVAILABLE_FORMATS.join(", ")}"
        ) do |formats|
          options[:formats] = formats.map(&:to_sym)

          invalid_formats = options[:formats] - Tahweel::Writer::AVAILABLE_FORMATS
          abort "Error: Invalid format(s): #{invalid_formats.join(", ")}" if invalid_formats.any?
        end

        opts.on(
          "--page-separator SEPARATOR", String,
          "Separator between pages in TXT output (default: #{Tahweel::Writers::Txt::PAGE_SEPARATOR.gsub("\n", "\\n")})"
        ) do |s|
          options[:page_separator] = s.gsub("\\n", "\n")
        end

        opts.on("-o", "--output DIR", String, "Output directory (default: current directory)") do |o|
          options[:output] = o
        end

        opts.on("-v", "--version", "Prints the version") do
          puts Tahweel::VERSION
          exit
        end

        opts.on("-h", "--help", "Prints this help") do
          puts opts
          exit
        end
      end

      def self.validate_args!(args, parser)
        return unless args.empty?

        puts parser
        exit 1
      end
    end
  end
end
