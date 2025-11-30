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
    allow(File).to receive(:exist?).and_return(false)
    allow(FileUtils).to receive(:mkdir_p)
    allow(Tahweel::Writer).to receive(:write)
    allow(Tahweel::Writer).to receive(:new).and_call_original
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

    context "when preserving directory structure" do
      let(:file_path) { "/data/input/subdir/test.pdf" }
      let(:options) do
        {
          output: "/output/dir",
          base_input_path: "/data/input",
          formats: [:txt]
        }
      end

      before do
        allow(Tahweel).to receive(:convert).and_return(["Text"])
      end

      it "mirrors the input directory structure in the output directory" do # rubocop:disable RSpec/MultipleExpectations
        processor.process

        expected_output_dir = "/output/dir/subdir"
        expect(FileUtils).to have_received(:mkdir_p).with(expected_output_dir)
        expect(Tahweel::Writer).to have_received(:write).with(
          ["Text"],
          File.join(expected_output_dir, "test"),
          formats: [:txt],
          page_separator: nil
        )
      end
    end

    context "when preserving directory structure with file at root" do
      let(:file_path) { "/data/input/test.pdf" }
      let(:options) do
        {
          output: "/output/dir",
          base_input_path: "/data/input",
          formats: [:txt]
        }
      end

      before do
        allow(Tahweel).to receive(:convert).and_return(["Text"])
      end

      it "outputs directly to the output directory without subdirectory" do # rubocop:disable RSpec/MultipleExpectations
        processor.process

        expect(FileUtils).to have_received(:mkdir_p).with("/output/dir")
        expect(Tahweel::Writer).to have_received(:write).with(
          ["Text"],
          "/output/dir/test",
          formats: [:txt],
          page_separator: nil
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
      let(:file_path) { "path/to/input.pdf" }
      let(:options) { { formats: [:txt] } }

      before do
        allow(Tahweel).to receive(:convert).and_return(["Text"])
      end

      it "defaults to the file's directory" do # rubocop:disable RSpec/MultipleExpectations
        processor.process

        expect(FileUtils).to have_received(:mkdir_p).with("path/to")
        expect(Tahweel::Writer).to have_received(:write).with(
          ["Text"],
          "path/to/input",
          formats: [:txt],
          page_separator: nil
        )
      end
    end

    context "when all output files already exist" do
      let(:file_path) { "input.pdf" }
      let(:options) { { formats: %i[txt docx], output: "/output/dir" } }

      before do
        # Mock File.exist? to return true for the expected output paths
        allow(File).to receive(:exist?).with("/output/dir/input.txt").and_return(true)
        allow(File).to receive(:exist?).with("/output/dir/input.docx").and_return(true)
        allow(Tahweel).to receive(:convert)
        allow(Tahweel).to receive(:extract)
      end

      it "skips processing" do # rubocop:disable RSpec/MultipleExpectations
        processor.process

        expect(Tahweel).not_to have_received(:convert)
        expect(Tahweel).not_to have_received(:extract)
        expect(Tahweel::Writer).not_to have_received(:write)
      end
    end

    context "when some output files are missing" do
      let(:file_path) { "input.pdf" }
      let(:options) { { formats: %i[txt docx], output: "/output/dir" } }

      before do
        allow(File).to receive(:exist?).with("/output/dir/input.txt").and_return(true)
        allow(File).to receive(:exist?).with("/output/dir/input.docx").and_return(false)
        allow(Tahweel).to receive(:convert).and_return(["Text"])
      end

      it "proceeds with processing" do # rubocop:disable RSpec/MultipleExpectations
        processor.process

        expect(Tahweel).to have_received(:convert)
        expect(Tahweel::Writer).to have_received(:write)
      end
    end
  end
end
