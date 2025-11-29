# frozen_string_literal: true

require "spec_helper"
require "tahweel/cli/file_processor"

RSpec.describe Tahweel::CLI::FileProcessor do
  subject(:processor) { described_class.new(file_path, options) }

  let(:options) do
    {
      output: "/output/dir",
      dpi: 300,
      processor: :test_processor,
      concurrency: 5,
      formats: [:txt],
      page_separator: "---"
    }
  end

  before do
    allow(FileUtils).to receive(:mkdir_p)
    allow(Tahweel::Writer).to receive(:write)
  end

  describe ".process" do
    it "instantiates and calls process" do # rubocop:disable RSpec/MultipleExpectations,RSpec/ExampleLength
      instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:process)

      described_class.process("file.pdf", options)

      expect(described_class).to have_received(:new).with("file.pdf", options)
      expect(instance).to have_received(:process)
    end
  end

  describe "#process" do
    context "when input is a PDF" do
      let(:file_path) { "input.pdf" }

      before do
        allow(Tahweel).to receive(:convert).and_return(["Page 1"])
      end

      it "converts the PDF and writes the output" do # rubocop:disable RSpec/MultipleExpectations
        processor.process

        expect(FileUtils).to have_received(:mkdir_p).with("/output/dir")
        expect(Tahweel).to have_received(:convert).with(
          file_path,
          dpi: 300,
          processor: :test_processor,
          concurrency: 5
        )
        expect(Tahweel::Writer).to have_received(:write).with(
          ["Page 1"],
          "/output/dir/input",
          formats: [:txt],
          page_separator: "---"
        )
      end
    end

    context "when input is an image" do
      let(:file_path) { "input.jpg" }

      before do
        allow(Tahweel).to receive(:extract).and_return("Extracted text")
      end

      it "extracts text from the image and writes the output" do # rubocop:disable RSpec/MultipleExpectations
        processor.process

        expect(FileUtils).to have_received(:mkdir_p).with("/output/dir")
        expect(Tahweel).to have_received(:extract).with(file_path, processor: :test_processor)
        expect(Tahweel::Writer).to have_received(:write).with(
          ["Extracted text"],
          "/output/dir/input",
          formats: [:txt],
          page_separator: "---"
        )
      end
    end

    context "when output directory is not specified" do
      let(:file_path) { "input.pdf" }
      let(:options) { { formats: [:txt] } }

      before do
        allow(Tahweel).to receive(:convert).and_return(["Text"])
        allow(Dir).to receive(:pwd).and_return("/current/dir")
      end

      it "defaults to current directory" do # rubocop:disable RSpec/MultipleExpectations
        processor.process

        expect(FileUtils).to have_received(:mkdir_p).with("/current/dir")
        expect(Tahweel::Writer).to have_received(:write).with(
          ["Text"],
          "/current/dir/input",
          formats: [:txt],
          page_separator: nil
        )
      end
    end
  end
end
