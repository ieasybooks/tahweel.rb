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
      # It applies several transformations to the text before writing:
      # 1. Normalizes all line endings (`\r\n`, `\r`) to `\n`.
      # 2. Collapses consecutive identical whitespace characters.
      # 3. Compacts the text by merging short lines if the page is too long (> 40 lines).
      # 4. Determines text alignment (RTL/LTR) based on content.
      # 5. Converts `\n` to proper OOXML line breaks for cross-platform compatibility.
      #
      # @param texts [Array<String>] The extracted texts (one per page).
      # @param destination [String] The output file path.
      # @param options [Hash] Options for writing (unused for now).
      # @return [void]
      def write(texts, destination, options = {}) # rubocop:disable Lint/UnusedMethodArgument
        Caracal::Document.save(destination) do |docx|
          texts.each_with_index do |text, index|
            text = text.gsub(/\r\n?/, "\n").gsub(/(\s)\1+/, '\1').strip
            text = compact_shortest_lines(text) while expected_lines_in_page(text) > 40

            write_paragraph(docx, text)

            docx.page if index < texts.size - 1
          end
        end
      end

      private

      # Writes a paragraph with proper OOXML line breaks.
      #
      # Raw newline characters (\n, \r\n) are not valid line breaks in DOCX format.
      # Microsoft Word on Windows requires proper <w:br/> elements for line breaks,
      # while macOS Pages is more lenient. This method uses Caracal's `br` method
      # to insert cross-platform compatible line breaks.
      #
      # @param docx [Caracal::Document] The document to write to.
      # @param text [String] The text content with newlines.
      # @return [void]
      def write_paragraph(docx, text)
        lines = text.split("\n")
        alignment = alignment_for(text)

        docx.p align: alignment do
          lines.each_with_index do |line, line_index|
            text line, size: 20
            br if line_index < lines.size - 1
          end
        end
      end

      # Determines the text alignment based on the ratio of Arabic to non-Arabic characters.
      #
      # @param text [String] The text to analyze.
      # @return [Symbol] :right if Arabic characters dominate, :left otherwise.
      def alignment_for(text)
        arabic_chars_count = text.scan(/\p{Arabic}/).count
        other_chars_count = text.scan(/[^\p{Arabic}\p{P}\d\s]/).count

        arabic_chars_count >= other_chars_count ? :right : :left
      end

      # Estimates the number of lines the text will occupy on a page.
      #
      # Assumes a line wraps if it exceeds 80 characters.
      #
      # @param text [String] The text to analyze.
      # @return [Integer] The estimated line count.
      def expected_lines_in_page(text) = text.count("\n") + 1 + text.split("\n").count { _1.length > 80 }

      # Compacts the text by merging the two shortest adjacent lines.
      #
      # @param text [String] The text to compact.
      # @return [String] The compacted text.
      def compact_shortest_lines(text)
        lines = text.split("\n")
        return text if lines.size < 2

        index = find_merge_index(lines)
        lines[index] = "#{lines[index]} #{lines[index + 1]}"
        lines.delete_at(index + 1)

        lines.join("\n")
      end

      # Finds the index of the first line in the pair of adjacent lines with the minimum combined length.
      #
      # @param lines [Array<String>] The lines to analyze.
      # @return [Integer] The index of the first line in the optimal pair.
      def find_merge_index(lines) = (0...(lines.size - 1)).min_by { lines[_1].length + lines[_1 + 1].length }
    end
  end
end
