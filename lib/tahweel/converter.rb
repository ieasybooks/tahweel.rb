# frozen_string_literal: true

require_relative "pdf_splitter"
require_relative "ocr"
require "fileutils"

module Tahweel
  # Orchestrates the full conversion process:
  # 1. Splits a PDF into images.
  # 2. Performs OCR on each image.
  # 3. Returns the aggregated text.
  # 4. Cleans up temporary files.
  class Converter
    # Convenience method to convert a PDF file to text.
    #
    # @param pdf_path [String] Path to the PDF file.
    # @param dpi [Integer] DPI for PDF to image conversion (default: 150).
    # @param processor [Symbol] OCR processor to use (default: :google_drive).
    # @return [Array<String>] An array containing the text of each page.
    def self.convert(pdf_path, dpi: PdfSplitter::DEFAULT_DPI, processor: :google_drive)
      new(pdf_path, dpi:, processor:).convert
    end

    # Initializes the Converter.
    #
    # @param pdf_path [String] Path to the PDF file.
    # @param dpi [Integer] DPI for PDF to image conversion.
    # @param processor [Symbol] OCR processor to use.
    def initialize(pdf_path, dpi: PdfSplitter::DEFAULT_DPI, processor: :google_drive)
      @pdf_path = pdf_path
      @dpi = dpi
      @processor_type = processor
    end

    # Executes the conversion process.
    #
    # @return [Array<String>] An array containing the text of each page.
    def convert
      image_paths, temp_dir = PdfSplitter.split(@pdf_path, dpi: @dpi).values_at(:image_paths, :folder_path)

      ocr_engine = Ocr.new(processor: @processor_type)
      texts = []

      begin
        image_paths.each { texts << ocr_engine.extract(_1) }
      ensure
        FileUtils.rm_rf(temp_dir)
      end

      texts
    end
  end
end
