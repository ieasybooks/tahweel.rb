# frozen_string_literal: true

require_relative "writers/txt"

module Tahweel
  # Factory class for writing extracted text to different formats.
  class Writer
    AVAILABLE_FORMATS = [:txt].freeze

    # Convenience method to write texts to files in the specified formats.
    #
    # @param texts [Array<String>] The extracted texts.
    # @param base_path [String] The base output path (without extension).
    # @param formats [Array<Symbol>] The output formats (default: [:txt]).
    # @param options [Hash] Options for writers.
    # @return [void]
    def self.write(texts, base_path, formats: [:txt], **options)
      formats.each { new(format: _1).write(texts, base_path, **options) }
    end

    # Initializes the Writer with a specific format strategy.
    #
    # @param format [Symbol] The output format.
    # @raise [ArgumentError] If the format is unknown.
    def initialize(format: :txt)
      @writer = case format
                when :txt then Writers::Txt.new
                else raise ArgumentError, "Unknown format: #{format}"
                end
    end

    # Writes the texts to the destination using the selected strategy.
    # Appends the appropriate extension to the base path.
    #
    # @param texts [Array<String>] The extracted texts.
    # @param base_path [String] The base output file path.
    # @param options [Hash] Options to pass to the writer.
    def write(texts, base_path, **options) = @writer.write(texts, "#{base_path}.#{@writer.extension}", options)
  end
end
