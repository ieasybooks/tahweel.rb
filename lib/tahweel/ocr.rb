# frozen_string_literal: true

require_relative "processors/google_drive"

module Tahweel
  # The main entry point for Optical Character Recognition (OCR).
  # This class acts as a factory/strategy context, delegating the actual extraction logic
  # to a specific processor.
  #
  # @example Usage with default processor (Google Drive)
  #   text = Tahweel::Ocr.extract("image.png")
  #
  # @example Usage with a specific processor (Future-proofing)
  #   # text = Tahweel::Ocr.extract("image.png", processor: :tesseract)
  class Ocr
    AVAILABLE_PROCESSORS = [:google_drive].freeze

    # Convenience method to extract text using a specific processor.
    #
    # @param file_path [String] Path to the image file.
    # @param processor [Symbol] The processor to use (default: :google_drive).
    # @return [String] The extracted text.
    def self.extract(file_path, processor: :google_drive)
      new(processor: processor).extract(file_path)
    end

    # Initializes the OCR engine with a specific processor strategy.
    #
    # @param processor [Symbol] The processor to use (default: :google_drive).
    # @raise [ArgumentError] If an unknown processor is specified.
    def initialize(processor: :google_drive)
      @processor = case processor
                   when :google_drive
                     Processors::GoogleDrive.new
                   else
                     raise ArgumentError, "Unknown processor: #{processor}"
                   end
    end

    # Extracts text from the file using the configured processor.
    #
    # @param file_path [String] Path to the image file.
    # @return [String] The extracted text.
    def extract(file_path)
      @processor.extract(file_path)
    end
  end
end
