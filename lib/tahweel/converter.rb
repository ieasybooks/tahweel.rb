# frozen_string_literal: true

require_relative "pdf_splitter"
require_relative "ocr"
require "fileutils"
require "async"
require "async/barrier"
require "async/semaphore"

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
    # @return [Array<String>] An array containing the text of each page.
    def self.convert(
      pdf_path, dpi: PdfSplitter::DEFAULT_DPI,
      processor: :google_drive,
      concurrency: DEFAULT_CONCURRENCY
    )
      new(pdf_path, dpi:, processor:, concurrency:).convert
    end

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
    # @return [Array<String>] An array containing the text of each page.
    def convert
      image_paths, temp_dir = PdfSplitter.split(@pdf_path, dpi: @dpi).values_at(:image_paths, :folder_path)

      ocr_engine = Ocr.new(processor: @processor_type)
      texts = Array.new(image_paths.size)

      begin
        process_images_concurrently(image_paths, ocr_engine, texts)
      ensure
        FileUtils.rm_rf(temp_dir)
      end

      texts
    end

    private

    def process_images_concurrently(image_paths, ocr_engine, texts)
      Async do
        barrier = Async::Barrier.new
        semaphore = Async::Semaphore.new(@concurrency, parent: barrier)

        image_paths.each_with_index do |image_path, index|
          semaphore.async do
            texts[index] = ocr_engine.extract(image_path)
          end
        end

        barrier.wait
      end
    end
  end
end
