# frozen_string_literal: true

require "fileutils"

require_relative "pdf_splitter"
require_relative "ocr"

module Tahweel
  # Orchestrates the full conversion process:
  # 1. Splits a PDF into images.
  # 2. Performs OCR on each image concurrently.
  # 3. Returns the aggregated text.
  # 4. Cleans up temporary files.
  class Converter
    # Max concurrent OCR operations to avoid hitting API rate limits too hard.
    DEFAULT_CONCURRENCY = 12

    # Convenience method to convert a PDF file to text.
    #
    # @param pdf_path [String] Path to the PDF file.
    # @param dpi [Integer] DPI for PDF to image conversion (default: 150).
    # @param processor [Symbol] OCR processor to use (default: :google_drive).
    # @param concurrency [Integer] Max concurrent OCR operations (default: 12).
    # @param &block [Proc] A block that will be yielded with progress info.
    # @yield [Hash] Progress info: {
    #   stage: :splitting or :ocr,
    #   current_page: Integer,
    #   percentage: Float,
    #   remaining_pages: Integer
    # }
    # @return [Array<String>] An array containing the text of each page.
    def self.convert(
      pdf_path,
      dpi: PdfSplitter::DEFAULT_DPI,
      processor: :google_drive,
      concurrency: DEFAULT_CONCURRENCY,
      &
    ) = new(pdf_path, dpi:, processor:, concurrency:).convert(&)

    # Initializes the Converter.
    #
    # @param pdf_path [String] Path to the PDF file.
    # @param dpi [Integer] DPI for PDF to image conversion.
    # @param processor [Symbol] OCR processor to use.
    # @param concurrency [Integer] Max concurrent OCR operations.
    def initialize(pdf_path, dpi: PdfSplitter::DEFAULT_DPI, processor: :google_drive, concurrency: DEFAULT_CONCURRENCY)
      @pdf_path = pdf_path
      @dpi = dpi
      @processor_type = processor
      @concurrency = concurrency
    end

    # Executes the conversion process.
    #
    # @param &block [Proc] A block that will be yielded with progress info.
    # @yield [Hash] Progress info: {
    #   stage: :splitting or :ocr,
    #   current_page: Integer,
    #   percentage: Float,
    #   remaining_pages: Integer
    # }
    # @return [Array<String>] An array containing the text of each page.
    def convert(&)
      images_paths, temp_dir = PdfSplitter.split(@pdf_path, dpi: @dpi, &).values_at(:images_paths, :folder_path)

      begin
        process_images(images_paths, Ocr.new(processor: @processor_type), &)
      ensure
        FileUtils.rm_rf(temp_dir)
      end
    end

    private

    def process_images(images_paths, ocr_engine, &)
      texts = Array.new(images_paths.size)
      mutex = Mutex.new
      processed_count = 0

      run_workers(build_queue(images_paths), ocr_engine, texts, mutex) do
        processed_count += 1
        report_progress(processed_count, images_paths.size, &)
      end

      texts
    end

    def build_queue(images_paths)
      queue = Queue.new
      images_paths.each_with_index { |path, index| queue << [path, index] }
      queue
    end

    def run_workers(queue, ocr_engine, texts, mutex, &)
      Array.new(@concurrency) do
        Thread.new { process_queue_items(queue, ocr_engine, texts, mutex, &) }
      end.each(&:join)
    end

    def process_queue_items(queue, ocr_engine, texts, mutex, &)
      loop do
        begin
          path, index = queue.pop(true)
        rescue ThreadError
          break
        end

        text = ocr_engine.extract(path)
        save_result(texts, index, text, mutex, &)
      end
    end

    def save_result(texts, index, text, mutex)
      mutex.synchronize do
        texts[index] = text
        yield
      end
    end

    def report_progress(processed, total)
      return unless block_given?

      yield({
        file_path: @pdf_path,
        stage: :ocr,
        current_page: processed,
        percentage: ((processed.to_f / total) * 100).round(2),
        remaining_pages: total - processed
      })
    end
  end
end
