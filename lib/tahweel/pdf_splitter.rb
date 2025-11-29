# frozen_string_literal: true

require "fileutils"
require "rbconfig"
require "securerandom"
require "tmpdir"
require "vips"

module Tahweel
  # Handles the logic for splitting a PDF file into individual image pages.
  # Uses the libvips library for high-performance image processing.
  class PdfSplitter
    # Default DPI used when converting PDF pages to images.
    # 150 DPI is a good balance between quality and file size for general documents.
    DEFAULT_DPI = 150

    # Convenience class method to initialize and execute the split operation in one go.
    #
    # @param pdf_path [String] The local file path to the PDF document.
    # @param dpi [Integer] The resolution (Dots Per Inch) for rendering the PDF pages. Defaults to 150.
    # @return [Hash] A hash containing the :folder_path (String) and :image_paths (Array<String>).
    def self.split(pdf_path, dpi: DEFAULT_DPI) = new(pdf_path, dpi:).split

    # Initializes a new PdfSplitter instance.
    #
    # @param pdf_path [String] The local file path to the PDF document.
    # @param dpi [Integer] The resolution (Dots Per Inch) to use. Defaults to 150.
    def initialize(pdf_path, dpi: DEFAULT_DPI)
      @pdf_path = pdf_path
      @dpi = dpi
      @image_paths = []
    end

    # Executes the PDF splitting process.
    #
    # This method performs the following steps:
    # 1. Checks if libvips is installed (skips on Windows).
    # 2. Validates the existence of the source PDF file.
    # 3. Creates a unique temporary directory for output.
    # 4. Iterates through each page of the PDF and converts it to a PNG image.
    #
    # @return [Hash] Result hash with keys:
    #   - :folder_path [String] The absolute path to the temporary directory containing the images.
    #   - :image_paths [Array<String>] List of absolute paths for each generated image file.
    # @raise [RuntimeError] If the PDF file is not found or libvips is missing.
    # @raise [Vips::Error] If the underlying VIPS library encounters an error during processing.
    def split
      check_libvips_installed!
      validate_file_exists!
      setup_output_directory
      process_pages
      result
    end

    private

    attr_reader :pdf_path, :dpi, :image_paths, :output_dir

    # Checks if the `vips` CLI tool is available in the system PATH.
    # Skips this check on Windows systems, assuming the environment is managed differently.
    # Aborts execution with an error message if vips is missing.
    def check_libvips_installed!
      return if /mswin|mingw|cygwin/.match?(RbConfig::CONFIG["host_os"])
      return if system("vips --version", out: File::NULL, err: File::NULL)

      abort "Error: libvips is not installed. Please install it before using Tahweel.\n" \
            "MacOS: `brew install vips`\n" \
            "Ubuntu: `sudo apt install libvips42`\n" \
            "Windows: Already installed with the Tahweel gem"
    end

    # Ensures the source PDF file actually exists.
    # @raise [RuntimeError] if the file is missing.
    def validate_file_exists!
      raise "File not found: #{pdf_path}" unless File.exist?(pdf_path)
    end

    # Creates a secure, unique temporary directory using UUIDs.
    def setup_output_directory
      @output_dir = File.join(Dir.tmpdir, "tahweel_#{SecureRandom.uuid}")
      FileUtils.mkdir_p(@output_dir)
    end

    # Iterates through all pages and extracts them.
    def process_pages = total_pages.times { extract_page(_1) }

    # Calculates the total number of pages in the PDF by loading the first page metadata.
    # @return [Integer] The page count.
    def total_pages
      @total_pages ||= Vips::Image.pdfload(pdf_path, page: 0, dpi: dpi, access: :sequential).get("pdf-n_pages")
    end

    # Extracts a specific page from the PDF and saves it as a PNG.
    #
    # @param page_num [Integer] The zero-based index of the page to extract.
    def extract_page(page_num)
      output_path = File.join(output_dir, "page_#{page_num + 1}.png")
      Vips::Image.pdfload(pdf_path, page: page_num, dpi: dpi, access: :sequential).write_to_file(output_path)
      image_paths << output_path
    end

    # Constructs the final result hash.
    # @return [Hash]
    def result
      {
        folder_path: output_dir,
        image_paths: image_paths
      }
    end
  end
end
