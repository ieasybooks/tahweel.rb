# frozen_string_literal: true

require "etc"
require "fileutils"
require "securerandom"
require "tmpdir"

require_relative "poppler_installer"

module Tahweel
  # Handles the logic for splitting a PDF file into individual image pages.
  # Uses Poppler utils (pdftoppm, pdfinfo) for high-performance image processing.
  class PdfSplitter
    # Default DPI used when converting PDF pages to images.
    # 150 DPI is a good balance between quality and file size for general documents.
    DEFAULT_DPI = 150

    # Convenience class method to initialize and execute the split operation in one go.
    #
    # @param pdf_path [String] The local file path to the PDF document.
    # @param dpi [Integer] The resolution (Dots Per Inch) for rendering the PDF pages. Defaults to 150.
    # @param &block [Proc] A block that will be yielded with progress info.
    # @yield [Hash] Progress info: {
    #   stage: :splitting,
    #   current_page: Integer,
    #   percentage: Float,
    #   remaining_pages: Integer
    # }
    # @return [Hash] A hash containing the :folder_path (String) and :images_paths (Array<String>).
    def self.split(pdf_path, dpi: DEFAULT_DPI, &) = new(pdf_path, dpi:).split(&)

    # Initializes a new PdfSplitter instance.
    #
    # @param pdf_path [String] The local file path to the PDF document.
    # @param dpi [Integer] The resolution (Dots Per Inch) to use. Defaults to 150.
    def initialize(pdf_path, dpi: DEFAULT_DPI)
      @pdf_path = pdf_path
      @dpi = dpi
    end

    # Executes the PDF splitting process.
    #
    # This method performs the following steps:
    # 1. Checks if Poppler utils are available (installs if missing on Windows).
    # 2. Validates the existence of the source PDF file.
    # 3. Creates a unique temporary directory for output.
    # 4. Iterates through each page of the PDF and converts it to a PNG image.
    #
    # @param &block [Proc] A block that will be yielded with progress info.
    # @yield [Hash] Progress info: {
    #   stage: :splitting,
    #   current_page: Integer,
    #   percentage: Float,
    #   remaining_pages: Integer
    # }
    # @return [Hash] Result hash with keys:
    #   - :folder_path [String] The absolute path to the temporary directory containing the images.
    #   - :images_paths [Array<String>] List of absolute paths for each generated image file.
    # @raise [RuntimeError] If the PDF file is not found.
    def split(&)
      validate_file_exists!
      PopplerInstaller.ensure_installed!
      setup_output_directory
      process_pages(&)
      result
    end

    private

    attr_reader :pdf_path, :dpi, :output_dir

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
    #
    # @param &block [Proc] A block that will be yielded with progress info.
    # @yield [Hash] Progress info: {
    #   stage: :splitting,
    #   current_page: Integer,
    #   percentage: Float,
    #   remaining_pages: Integer
    # }
    # @return [void]
    def process_pages(&)
      mutex = Mutex.new
      processed_count = 0

      run_workers(build_queue, mutex) do
        processed_count += 1
        report_progress(processed_count, &)
      end
    end

    # Builds a queue containing all page indices to be processed.
    # @return [Queue] The queue populated with page numbers.
    def build_queue
      queue = Queue.new
      total_pages.times { queue << _1 }
      queue
    end

    # Spawns and manages worker threads to process the queue.
    #
    # @param queue [Queue] The queue of pages to process.
    # @param mutex [Mutex] Synchronization primitive for thread safety.
    # @param &block [Proc] Block to execute when a page is processed.
    def run_workers(queue, mutex, &)
      concurrency = (Etc.nprocessors - 2).clamp(2..)

      Array.new([concurrency, total_pages].min) do
        Thread.new { process_queue_items(queue, mutex, &) }
      end.each(&:join)
    end

    # Processing loop for individual worker threads.
    #
    # @param queue [Queue] The shared queue of pages.
    # @param mutex [Mutex] Synchronization primitive.
    # @param &block [Proc] Block to yield for progress updates.
    def process_queue_items(queue, mutex, &)
      loop do
        begin
          page_num = queue.pop(true)
        rescue ThreadError
          break
        end

        extract_page(page_num)

        mutex.synchronize(&)
      end
    end

    # Reports progress back to the caller.
    #
    # @param processed [Integer] Number of pages processed so far.
    # @param &block [Proc] The progress callback block.
    def report_progress(processed, &)
      return unless block_given?

      yield({
        file_path: @pdf_path, stage: :splitting,
        current_page: processed,
        percentage: ((processed.to_f / total_pages) * 100).round(2),
        remaining_pages: total_pages - processed
      })
    end

    # Calculates the total number of pages in the PDF by loading the first page metadata.
    # @return [Integer] The page count.
    def total_pages
      @total_pages ||= begin
        output = `#{PopplerInstaller.pdfinfo_path} "#{pdf_path}"`
                 .b # Force to binary to handle Windows encoding issues
                 .encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

        pages = output[/Pages:\s*(\d+)/, 1]
        raise "Failed to get page count from PDF: #{output}" unless pages

        pages.to_i
      end
    end

    # Extracts a specific page from the PDF and saves it as a PNG.
    #
    # @param page_num [Integer] The zero-based index of the page to extract.
    def extract_page(page_num)
      output_prefix = File.join(output_dir, "page")

      system(
        PopplerInstaller.pdftoppm_path,
        "-png",
        "-r", dpi.to_s,
        "-f", (page_num + 1).to_s,
        "-l", (page_num + 1).to_s,
        pdf_path,
        output_prefix
      )
    end

    # Constructs the final result hash.
    # @return [Hash]
    def result
      {
        folder_path: output_dir,
        images_paths: Dir.glob(File.join(output_dir, "page-*.png")).sort!
      }
    end
  end
end
