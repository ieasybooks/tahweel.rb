# frozen_string_literal: true

require "caracal"

module Tahweel
  module Writers
    # Writer class for outputting text to a .docx file.
    class Docx
      # Returns the file extension for this writer.
      #
      # @return [String] The file extension.
      def extension = "docx"

      # Writes the extracted texts to a file.
      #
      # @param texts [Array<String>] The extracted texts (one per page).
      # @param destination [String] The output file path.
      # @param options [Hash] Options for writing (unused for now).
      # @return [void]
      def write(texts, destination, options = {}) # rubocop:disable Lint/UnusedMethodArgument
        Caracal::Document.save(destination) do |docx|
          texts.each_with_index do |text, index|
            docx.p text.gsub(/(\r\n)+/, "\n").gsub(/(\s)\1+/, '\1').strip

            docx.page if index < texts.size - 1
          end
        end
      end
    end
  end
end
