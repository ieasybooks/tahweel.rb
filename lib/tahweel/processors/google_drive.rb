# frozen_string_literal: true

require "google/apis/drive_v3"
require "securerandom"
require "stringio"

require_relative "../authorizer"

module Tahweel
  module Processors
    # Handles the conversion of images to text using Google Drive's OCR capabilities.
    #
    # This class automates the process of:
    # 1. Uploading a local image to Google Drive as a Google Document.
    # 2. Downloading the content of that document as plain text.
    # 3. Cleaning up (deleting) the temporary file from Drive.
    #
    # It includes robust error handling with infinite retries and exponential backoff
    # for network issues, rate limits, and server errors.
    class GoogleDrive
      # Initializes the Google Drive OCR service.
      # Sets up the Google Drive API client and authorizes it using {Tahweel::Authorizer}.
      #
      # @note This operation performs filesystem I/O to read credentials.
      #   For bulk processing, instantiate this once and reuse it.
      def initialize
        @service = Google::Apis::DriveV3::DriveService.new
        @service.client_options.application_name = "Tahweel"
        @service.authorization = Tahweel::Authorizer.authorize
      end

      # Extracts text from an image file using the "Upload -> Export -> Delete" flow.
      #
      # The method ensures that the temporary file created on Google Drive is deleted
      # regardless of whether the download succeeds or fails.
      #
      # @param file_path [String] The path to the image file.
      # @return [String] The extracted text.
      # @raise [RuntimeError] If the file does not exist locally.
      # @raise [Google::Apis::Error] If a non-retriable API error occurs (e.g., 401, 403, 404).
      def extract(file_path)
        raise "File not found: #{file_path}" unless File.exist?(file_path)

        file_id = upload_file(file_path)

        begin
          download_text(file_id).gsub("\r\n", "\n").gsub("﻿________________", "").strip
        ensure
          delete_file(file_id)
        end
      end

      private

      # Uploads the file to Google Drive with the MIME type set to 'application/vnd.google-apps.document'.
      # This triggers Google's automatic OCR processing.
      #
      # @param file_path [String] Path to the local file.
      # @return [String] The ID of the created file on Google Drive.
      def upload_file(file_path)
        execute_with_retry do
          @service.create_file(
            {
              name: SecureRandom.uuid,
              mime_type: "application/vnd.google-apps.document"
            },
            upload_source: file_path,
            fields: "id"
          ).id
        end
      end

      # Exports the Google Document as plain text.
      #
      # @param file_id [String] The ID of the file on Google Drive.
      # @return [String] The content of the file as a string.
      def download_text(file_id)
        execute_with_retry do
          StringIO.new.tap do |dest|
            @service.export_file(file_id, "text/plain", download_dest: dest)
          end.string
        end
      end

      # Deletes the temporary file from Google Drive.
      #
      # @param file_id [String] The ID of the file to delete.
      # @return [void]
      def delete_file(file_id) = execute_with_retry { @service.delete_file(file_id) }

      # Executes a block with infinite retries and exponential backoff.
      # Designed to handle transient errors (Rate Limits, Network issues, Server errors).
      #
      # @yield The block to execute.
      # @raise [Google::Apis::Error] Rethrows non-retriable errors immediately.
      def execute_with_retry
        retries = 0

        begin
          yield
        rescue Google::Apis::RateLimitError, Google::Apis::TransmissionError, Google::Apis::ServerError => e
          # Exponential backoff with a cap of 60 seconds + jitter
          wait_time = [2**retries, 60].min + rand
          sleep wait_time
          retries += 1
          retry
        end
      end
    end
  end
end
