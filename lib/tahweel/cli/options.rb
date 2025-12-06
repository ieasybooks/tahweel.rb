# frozen_string_literal: true

require "etc"
require "optparse"

require_relative "../version"
require_relative "../converter"
require_relative "../ocr"
require_relative "../writer"
require_relative "../writers/txt"
require_relative "file_collector"

module Tahweel
  module CLI
    # Parses command-line arguments for the Tahweel CLI.
    class Options
      POSITIVE_INTEGER = /\A\+?[1-9]\d*(?:_\d+)*\z/

      # Parses the command-line arguments.
      #
      # @param args [Array<String>] The command-line arguments.
      # @return [Hash] The parsed options.
      def self.parse(args)
        options = default_options
        parser = OptionParser.new { configure_parser(_1, options) }
        begin
          parser.parse!(args)
        rescue OptionParser::ParseError => e
          abort "Error: #{e.message}"
        end

        validate_args!(args, parser)
        options
      end

      # Returns the default configuration options.
      # @return [Hash] Default options.
      def self.default_options
        {
          dpi: 150,
          processor: :google_drive,
          ocr_concurrency: Tahweel::Converter::DEFAULT_CONCURRENCY,
          file_concurrency: (Etc.nprocessors - 2).clamp(2..),
          output: nil,
          formats: %i[txt docx],
          page_separator: Tahweel::Writers::Txt::PAGE_SEPARATOR
        }
      end

      # Configures the OptionParser instance.
      #
      # @param opts [OptionParser] The parser instance.
      # @param options [Hash] The options hash to populate.
      def self.configure_parser(opts, options) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
        opts.program_name = "tahweel"
        opts.version = Tahweel::VERSION

        opts.accept(POSITIVE_INTEGER) do |value|
          n = Integer(value)
          raise OptionParser::InvalidArgument, "must be a positive integer" if n < 1

          n
        end

        opts.on(
          "-e", "--extensions EXTENSIONS", Array,
          "Comma-separated list of file extensions to process " \
          "(default: #{Tahweel::CLI::FileCollector::SUPPORTED_EXTENSIONS.join(", ")})"
        ) do |value|
          options[:extensions] = value
        end

        opts.on("--dpi DPI", POSITIVE_INTEGER, "DPI for PDF to Image conversion (default: #{options[:dpi]})") do |value|
          options[:dpi] = value
        end

        opts.on(
          "-p", "--processor PROCESSOR", Tahweel::Ocr::AVAILABLE_PROCESSORS,
          "OCR processor to use (default: google_drive). Available: #{Tahweel::Ocr::AVAILABLE_PROCESSORS.join(", ")}"
        ) do |value|
          options[:processor] = value
        end

        opts.on(
          "-F", "--file-concurrency FILE_CONCURRENCY", POSITIVE_INTEGER,
          "Max concurrent files to process (default: CPUs - 2 = #{options[:file_concurrency]})"
        ) do |value|
          options[:file_concurrency] = value
        end

        opts.on(
          "-O", "--ocr-concurrency OCR_CONCURRENCY", POSITIVE_INTEGER,
          "Max concurrent OCR operations (default: #{options[:ocr_concurrency]})"
        ) do |value|
          options[:ocr_concurrency] = value
        end

        opts.on(
          "-f", "--formats FORMATS", Array,
          "Output formats (comma-separated, default: txt). Available: #{Tahweel::Writer::AVAILABLE_FORMATS.join(", ")}"
        ) do |value|
          options[:formats] = value.map(&:to_sym)

          invalid_formats = options[:formats] - Tahweel::Writer::AVAILABLE_FORMATS
          abort "Error: invalid format(s): #{invalid_formats.join(", ")}" if invalid_formats.any?
        end

        opts.on(
          "--page-separator SEPARATOR", String,
          "Separator between pages in TXT output (default: #{options[:page_separator].gsub("\n", "\\n")})"
        ) do |value|
          options[:page_separator] = value.gsub("\\n", "\n")
        end

        opts.on("-o", "--output DIR", String, "Output directory (default: current directory)") do |value|
          options[:output] = value
        end
      end

      # Validates that arguments were provided.
      #
      # @param args [Array<String>] The remaining arguments after parsing.
      # @param parser [OptionParser] The parser instance for printing help.
      def self.validate_args!(args, parser)
        return unless args.empty?

        puts parser
        exit 1
      end
    end
  end
end
