# frozen_string_literal: true

module Tahweel
  module CLI
    # Collects files for processing from a given input path.
    #
    # This utility class handles the logic of discovering files to process.
    # It supports both single file paths and directory recursion.
    class FileCollector
      SUPPORTED_EXTENSIONS = %w[pdf jpg jpeg png].freeze

      # Collects files from the input path based on supported or provided extensions.
      #
      # If the input path is a directory, it performs a recursive case-insensitive glob search
      # for files matching the specified extensions.
      #
      # If the input path is a file, it returns it as a single-element array, assuming
      # the user explicitly wants to process it regardless of extension.
      #
      # @param input_path [String] The path to the file or directory.
      # @param extensions [Array<String>] Optional list of extensions to filter by (e.g., `["pdf"]`).
      #   Defaults to {SUPPORTED_EXTENSIONS} if not provided.
      # @return [Array<String>] An alphabetical sorted array of absolute file paths.
      def self.collect(input_path, extensions: nil)
        return [input_path] unless File.directory?(input_path)

        extensions ||= SUPPORTED_EXTENSIONS
        glob_pattern = File.join(input_path, "**", "*.{#{extensions.join(",")}}")
        Dir.glob(glob_pattern, File::FNM_CASEFOLD).sort
      end
    end
  end
end
