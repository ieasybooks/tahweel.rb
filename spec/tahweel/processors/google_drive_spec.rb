# frozen_string_literal: true

require "spec_helper"
require "tahweel/processors/google_drive"

RSpec.describe Tahweel::Processors::GoogleDrive do
  subject(:processor) { described_class.new }

  let(:mock_service) { instance_double(Google::Apis::DriveV3::DriveService) }
  # Use simple double as RequestOptions methods are dynamic/missing in some versions
  let(:mock_client_options) { double("RequestOptions") } # rubocop:disable RSpec/VerifiedDoubles
  let(:mock_file) { instance_double(Google::Apis::DriveV3::File, id: "file_123") }
  let(:file_path) { "test.jpg" }

  before do
    # Mock DriveService and its setup
    allow(Google::Apis::DriveV3::DriveService).to receive(:new).and_return(mock_service)
    allow(mock_service).to receive(:client_options).and_return(mock_client_options)
    allow(mock_client_options).to receive(:application_name=)
    allow(mock_service).to receive(:authorization=)
    allow(Tahweel::Authorizer).to receive(:authorize).and_return(:creds)

    # Mock file system checks
    allow(File).to receive(:exist?).with(file_path).and_return(true)
    allow(File).to receive(:basename).with(file_path).and_return("test.jpg")
  end

  describe "#initialize" do
    it "sets up the drive service with authorization" do # rubocop:disable RSpec/MultipleExpectations
      processor # trigger initialize

      expect(mock_client_options).to have_received(:application_name=).with("Tahweel")
      expect(mock_service).to have_received(:authorization=).with(:creds)
    end
  end

  describe "#extract" do
    before do
      # Default success scenario mocks
      allow(mock_service).to receive(:create_file).and_return(mock_file)
      allow(mock_service).to receive(:export_file) do |_file_id, _mime, options|
        options[:download_dest].write("Extracted Text")
        options[:download_dest].rewind
      end
      allow(mock_service).to receive(:delete_file)
    end

    context "when the file does not exist" do
      before do
        allow(File).to receive(:exist?).with(file_path).and_return(false)
      end

      it "raises a RuntimeError" do
        expect { processor.extract(file_path) }.to raise_error(RuntimeError, /File not found/)
      end
    end

    context "when the file exists" do
      it "performs the upload, download, and delete flow" do # rubocop:disable RSpec/MultipleExpectations
        result = processor.extract(file_path)

        expect(result).to eq("Extracted Text")

        # Verify Upload
        expect(mock_service).to have_received(:create_file).with(
          { name: "test.jpg", mime_type: "application/vnd.google-apps.document" },
          upload_source: file_path,
          fields: "id"
        )

        # Verify Download
        expect(mock_service).to have_received(:export_file).with(
          "file_123",
          "text/plain",
          download_dest: an_instance_of(StringIO)
        )

        # Verify Delete
        expect(mock_service).to have_received(:delete_file).with("file_123")
      end
    end

    context "when an error occurs during download" do
      before do
        allow(mock_service).to receive(:export_file).and_raise(RuntimeError, "Download Failed")
      end

      it "ensures the file is deleted" do # rubocop:disable RSpec/MultipleExpectations
        expect { processor.extract(file_path) }.to raise_error(RuntimeError, "Download Failed")

        expect(mock_service).to have_received(:delete_file).with("file_123")
      end
    end

    describe "retry logic" do
      # We'll test the retry logic on one of the operations (e.g. upload)
      # since they all share the same private `execute_with_retry` method.

      it "retries on transient errors and eventually succeeds" do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
        # Fail twice, then succeed
        call_count = 0
        allow(mock_service).to receive(:create_file) do
          call_count += 1
          raise Google::Apis::RateLimitError, "Rate limit exceeded" if call_count <= 2

          mock_file
        end

        # Mock sleep to speed up tests
        allow(processor).to receive(:sleep) # rubocop:disable RSpec/SubjectStub

        processor.extract(file_path)

        expect(mock_service).to have_received(:create_file).exactly(3).times
        expect(processor).to have_received(:sleep).twice # rubocop:disable RSpec/SubjectStub
      end

      it "retries on server errors" do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
        call_count = 0
        allow(mock_service).to receive(:create_file) do
          call_count += 1
          raise Google::Apis::ServerError, "Server Error" if call_count == 1

          mock_file
        end

        allow(processor).to receive(:sleep) # rubocop:disable RSpec/SubjectStub

        processor.extract(file_path)

        expect(mock_service).to have_received(:create_file).twice
        expect(processor).to have_received(:sleep).once # rubocop:disable RSpec/SubjectStub
      end

      it "does NOT retry on permanent errors (e.g. 404)" do
        # Google::Apis::ClientError is NOT in the rescue list
        allow(mock_service).to receive(:create_file).and_raise(Google::Apis::ClientError.new("Not Found"))

        expect { processor.extract(file_path) }.to raise_error(Google::Apis::ClientError)
      end
    end
  end
end
