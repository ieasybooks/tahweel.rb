# frozen_string_literal: true

require "spec_helper"
require "tahweel/pdf_splitter"

RSpec.describe Tahweel::PdfSplitter do
  let(:pdf_path) { "test.pdf" }
  let(:output_dir) { "/tmp/tahweel_uuid" }
  let(:splitter) { described_class.new(pdf_path, dpi: 150) }
  let(:pdftoppm_path) { "pdftoppm" }
  let(:pdfinfo_path) { "pdfinfo" }

  before do
    # Mock filesystem checks
    allow(File).to receive(:exist?).with(pdf_path).and_return(true)
    allow(SecureRandom).to receive(:uuid).and_return("uuid")
    allow(FileUtils).to receive(:mkdir_p)
    allow(Dir).to receive_messages(tmpdir: "/tmp", glob: [])

    # Mock Poppler Installer
    allow(Tahweel::PopplerInstaller).to receive(:ensure_installed!)
    allow(Tahweel::PopplerInstaller).to receive_messages(pdftoppm_path:, pdfinfo_path:)

    # Mock pdfinfo execution
    allow(splitter).to receive(:`).with(/#{pdfinfo_path} "#{pdf_path}"/).and_return("Pages: 2\n")

    # Mock system execution for pdftoppm
    allow(splitter).to receive(:system).with(pdftoppm_path, any_args).and_return(true)
  end

  describe ".split" do
    it "instantiates and calls split" do
      instance = instance_spy(described_class)
      allow(described_class).to receive(:new).with(pdf_path, dpi: 150).and_return(instance)

      described_class.split(pdf_path)

      expect(instance).to have_received(:split)
    end
  end

  describe "#split" do
    context "when everything is valid" do
      it "ensures Poppler is installed" do
        splitter.split
        expect(Tahweel::PopplerInstaller).to have_received(:ensure_installed!)
      end

      it "creates a temporary directory" do
        splitter.split
        expect(FileUtils).to have_received(:mkdir_p).with(output_dir)
      end

      it "gets total pages using pdfinfo" do
        splitter.split
        expect(splitter).to have_received(:`).with(/#{pdfinfo_path} "#{pdf_path}"/)
      end

      it "processes all pages" do # rubocop:disable RSpec/MultipleExpectations
        splitter.split

        # Expect pdftoppm execution for page 1 and 2
        expect(splitter).to have_received(:system).with(
          pdftoppm_path, "-png", "-r", "150", "-f", "1", "-l", "1", "\"test.pdf\"", "\"#{output_dir}/page\""
        )

        expect(splitter).to have_received(:system).with(
          pdftoppm_path, "-png", "-r", "150", "-f", "2", "-l", "2", "\"test.pdf\"", "\"#{output_dir}/page\""
        )
      end

      it "returns the expected result hash" do # rubocop:disable RSpec/MultipleExpectations
        allow(Dir).to receive(:glob).with(File.join(output_dir, "page_*.png")).and_return(
          ["#{output_dir}/page_1.png", "#{output_dir}/page_2.png"]
        )

        result = splitter.split

        expect(result[:folder_path]).to eq(output_dir)
        expect(result[:images_paths]).to include(
          "#{output_dir}/page_1.png",
          "#{output_dir}/page_2.png"
        )
      end
    end

    context "when a block is given for progress" do
      it "yields progress updates" do # rubocop:disable RSpec/MultipleExpectations
        expect { |b| splitter.split(&b) }.to yield_control.exactly(2).times

        expect { |b| splitter.split(&b) }.to yield_successive_args(
          {
            file_path: pdf_path,
            stage: :splitting,
            current_page: 1,
            percentage: 50.0,
            remaining_pages: 1
          },
          {
            file_path: pdf_path,
            stage: :splitting,
            current_page: 2,
            percentage: 100.0,
            remaining_pages: 0
          }
        )
      end
    end

    context "when PDF file does not exist" do
      before do
        allow(File).to receive(:exist?).with(pdf_path).and_return(false)
      end

      it "raises a RuntimeError" do
        expect { splitter.split }.to raise_error(RuntimeError, /File not found/)
      end
    end

    context "when pdfinfo fails to return page count" do
      before do
        allow(splitter).to receive(:`).with(/#{pdfinfo_path} "#{pdf_path}"/).and_return("Error processing PDF")
      end

      it "raises a RuntimeError" do
        expect { splitter.split }.to raise_error(RuntimeError, /Failed to get page count from PDF/)
      end
    end
  end
end
