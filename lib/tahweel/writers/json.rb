# frozen_string_literal: true

require "json"

module Tahweel
  module Writers
    # Writer class for outputting text to a .json file.
    class Json
      # Returns the file extension for this writer.
      #
      # @return [String] The file extension.
      def extension = "json"

      # Writes the extracted texts to a file.
      #
      # @param texts [Array<String>] The extracted texts (one per page).
      # @param destination [String] The output file path.
      # @param options [Hash] Options for writing (unused for now).
      # @return [void]
      def write(texts, destination, options = {}) # rubocop:disable Lint/UnusedMethodArgument
        structured_data = texts.map.with_index do |text, index|
          {
            page: index + 1,
            content: text
          }
        end

        File.write(destination, JSON.pretty_generate(structured_data))
      end
    end
  end
end
