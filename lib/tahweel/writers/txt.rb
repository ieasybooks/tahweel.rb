# frozen_string_literal: true

module Tahweel
  module Writers
    # Writer class for outputting text to a .txt file.
    class Txt
      PAGE_SEPARATOR = "\n\nPAGE_SEPARATOR\n\n"

      # Returns the file extension for this writer.
      #
      # @return [String] The file extension.
      def extension = "txt"

      # Writes the extracted texts to a file.
      #
      # @param texts [Array<String>] The extracted texts (one per page).
      # @param destination [String] The output file path.
      # @param options [Hash] Options for writing.
      # @option options [String] :page_separator (PAGE_SEPARATOR) Separator between pages.
      # @return [void]
      def write(texts, destination, options = {})
        separator = options[:page_separator] || PAGE_SEPARATOR
        File.write(destination, texts.map(&:strip).join(separator))
      end
    end
  end
end
