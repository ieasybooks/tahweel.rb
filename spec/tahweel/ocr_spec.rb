# frozen_string_literal: true

require "spec_helper"
require "tahweel/ocr"

RSpec.describe Tahweel::Ocr do
  let(:google_drive_processor) { instance_double(Tahweel::Processors::GoogleDrive) }
  let(:file_path) { "test_image.png" }

  before do
    # Mock the processor initialization
    allow(Tahweel::Processors::GoogleDrive).to receive(:new).and_return(google_drive_processor)
    allow(google_drive_processor).to receive(:extract).with(file_path).and_return("Extracted Text")
  end

  describe ".extract" do
    it "instantiates a new Ocr instance and delegates to #extract" do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:extract).with(file_path)

      described_class.extract(file_path)

      expect(described_class).to have_received(:new).with(processor: :google_drive)
      expect(instance).to have_received(:extract).with(file_path)
    end

    it "allows overriding the processor" do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:extract).with(file_path)

      described_class.extract(file_path, processor: :custom)

      expect(described_class).to have_received(:new).with(processor: :custom)
      expect(instance).to have_received(:extract).with(file_path)
    end
  end

  describe "#initialize" do
    it "initializes with :google_drive processor by default" do
      described_class.new

      expect(Tahweel::Processors::GoogleDrive).to have_received(:new)
    end

    it "initializes with :google_drive processor explicitly" do
      described_class.new(processor: :google_drive)

      expect(Tahweel::Processors::GoogleDrive).to have_received(:new)
    end

    it "raises ArgumentError for unknown processors" do
      expect { described_class.new(processor: :unknown) }.to raise_error(ArgumentError, "Unknown processor: unknown")
    end
  end

  describe "#extract" do
    it "delegates extraction to the configured processor" do # rubocop:disable RSpec/MultipleExpectations
      ocr = described_class.new(processor: :google_drive)
      result = ocr.extract(file_path)

      expect(result).to eq("Extracted Text")
      expect(google_drive_processor).to have_received(:extract).with(file_path)
    end
  end
end
