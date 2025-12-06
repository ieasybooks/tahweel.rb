# frozen_string_literal: true

require "fileutils"
require "pathname"

module Tahweel
  module CLI
    # Processes a single file by orchestrating conversion/extraction and writing the output.
    #
    # This class acts as the bridge between the CLI inputs and the core library logic.
    # It determines the file type (PDF or Image), calls the appropriate processing method,
    # and directs the results to the {Tahweel::Writer}.
    class FileProcessor
      # Processes the given file according to the provided options.
      #
      # @param file_path [String] The path to the input file.
      # @param options [Hash] Configuration options.
      # @option options [String] :output The directory to save output files (defaults to current directory).
      # @option options [Integer] :dpi DPI for PDF conversion (defaults to 150).
      # @option options [Symbol] :processor The OCR processor to use (e.g., :google_drive).
      # @option options [Integer] :ocr_concurrency Max concurrent operations.
      # @option options [Array<Symbol>] :formats Output formats (e.g., [:txt, :docx]).
      # @option options [String] :page_separator Separator string for TXT output.
      # @option options [String] :base_input_path The base path used to determine relative output structure.
      # @param &block [Proc] A block that will be yielded with progress info.
      # @yield [Hash] Progress info: {
      #   stage: :splitting or :ocr,
      #   current_page: Integer,
      #   percentage: Float,
      #   remaining_pages: Integer
      # }
      # @return [void]
      def self.process(file_path, options, &) = new(file_path, options).process(&)

      # Initializes a new FileProcessor.
      #
      # @param file_path [String] The path to the input file.
      # @param options [Hash] Configuration options (see {.process}).
      def initialize(file_path, options)
        @file_path = file_path
        @options = options
      end

      # Executes the processing logic.
      #
      # 1. Ensures the output directory exists.
      # 2. Checks if output files already exist to avoid redundant processing.
      # 3. Detects if the input is a PDF or an image.
      # 4. Runs the appropriate conversion/extraction pipeline.
      # 5. Writes the results to the configured formats.
      #
      # @param &block [Proc] A block that will be yielded with progress info.
      # @yield [Hash] Progress info: {
      #   stage: :splitting or :ocr,
      #   current_page: Integer,
      #   percentage: Float,
      #   remaining_pages: Integer
      # }
      # @return [void]
      def process(&)
        ensure_output_directory_exists

        return if all_outputs_exist?

        pdf? ? process_pdf(&) : process_image
      end

      private

      def ensure_output_directory_exists = FileUtils.mkdir_p(output_directory)

      def all_outputs_exist?
        @options[:formats].all? do |format|
          extension = Tahweel::Writer.new(format: format).extension
          File.exist?("#{base_output_path}.#{extension}")
        end
      end

      def pdf? = File.extname(@file_path).downcase == ".pdf"

      def process_pdf(&)
        texts = Tahweel.convert(
          @file_path,
          dpi: @options[:dpi],
          processor: @options[:processor],
          concurrency: @options.fetch(:ocr_concurrency, Tahweel::Converter::DEFAULT_CONCURRENCY),
          &
        )

        write_output(texts)
      end

      def process_image = write_output([Tahweel.extract(@file_path, processor: @options[:processor])])

      def write_output(texts)
        Tahweel::Writer.write(
          texts,
          base_output_path,
          formats: @options[:formats],
          page_separator: @options[:page_separator]
        )
      end

      def base_output_path = File.join(output_directory, File.basename(@file_path, ".*"))

      # Determines the output directory.
      #
      # If an output option is provided, it attempts to preserve the directory structure
      # relative to the `base_input_path`. If `base_input_path` is not provided or
      # calculation fails, it falls back to the provided output directory.
      #
      # If no output option is provided, it defaults to the file's own directory.
      #
      # @return [String] The target output directory.
      def output_directory
        return File.dirname(@file_path) unless @options[:output]

        if @options[:base_input_path]
          relative_dir = Pathname.new(File.dirname(@file_path)).relative_path_from(@options[:base_input_path])
          return File.join(@options[:output], relative_dir) unless relative_dir.to_s == "."
        end

        @options[:output]
      end
    end
  end
end
