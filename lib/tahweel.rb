# frozen_string_literal: true

require_relative "tahweel/version"
require_relative "tahweel/authorizer"
require_relative "tahweel/pdf_splitter"
require_relative "tahweel/ocr"
require_relative "tahweel/converter"

module Tahweel # rubocop:disable Style/Documentation
  class Error < StandardError; end

  # Converts a PDF file to text by splitting it into images and running OCR on each page.
  #
  # @param pdf_path [String] Path to the PDF file.
  # @param dpi [Integer] DPI for PDF to image conversion (default: 150).
  # @param processor [Symbol] OCR processor to use (default: :google_drive).
  # @return [Array<String>] An array containing the text of each page.
  def self.convert(pdf_path, dpi: PdfSplitter::DEFAULT_DPI, processor: :google_drive)
    Converter.convert(pdf_path, dpi:, processor:)
  end

  # Extracts text from an image file using the specified OCR processor.
  #
  # @param image_path [String] Path to the image file.
  # @param processor [Symbol] OCR processor to use (default: :google_drive).
  # @return [String] The extracted text.
  def self.extract(image_path, processor: :google_drive)
    Ocr.extract(image_path, processor:)
  end
end
