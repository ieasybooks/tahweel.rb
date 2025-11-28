# frozen_string_literal: true

require "spec_helper"
require "tahweel/pdf_splitter"

RSpec.describe Tahweel::PdfSplitter do
  let(:pdf_path) { "test.pdf" }
  let(:output_dir) { "/tmp/tahweel_uuid" }
  let(:mock_image) { instance_spy(Vips::Image) }
  let(:splitter) { described_class.new(pdf_path, dpi: 150) }

  before do
    # Mock filesystem checks
    allow(File).to receive(:exist?).with(pdf_path).and_return(true)
    allow(Dir).to receive(:tmpdir).and_return("/tmp")
    allow(SecureRandom).to receive(:uuid).and_return("uuid")
    allow(FileUtils).to receive(:mkdir_p)

    # Mock Vips interactions
    allow(Vips::Image).to receive(:pdfload).and_return(mock_image)
    allow(mock_image).to receive(:get).with("pdf-n_pages").and_return(2)

    # Mock system check for libvips (return true by default)
    allow(splitter).to receive(:system).with(/vips --version/, any_args).and_return(true)

    # Ensure we are testing as non-Windows by default
    stub_const("RbConfig::CONFIG", { "host_os" => "darwin" })
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
      it "creates a temporary directory" do
        splitter.split
        expect(FileUtils).to have_received(:mkdir_p).with(output_dir)
      end

      it "processes all pages" do # rubocop:disable RSpec/MultipleExpectations
        splitter.split

        # Expect pdfload for page 0 (metadata) + page 0 (extract) + page 1 (extract)
        expect(Vips::Image).to have_received(:pdfload).with(pdf_path, page: 0, dpi: 150, access: :sequential).twice
        expect(Vips::Image).to have_received(:pdfload).with(pdf_path, page: 1, dpi: 150, access: :sequential).once
      end

      it "writes images to the output directory" do # rubocop:disable RSpec/MultipleExpectations
        splitter.split

        expect(mock_image).to have_received(:write_to_file).with("/tmp/tahweel_uuid/page_1.png")
        expect(mock_image).to have_received(:write_to_file).with("/tmp/tahweel_uuid/page_2.png")
      end

      it "returns the expected result hash" do # rubocop:disable RSpec/MultipleExpectations
        result = splitter.split

        expect(result[:folder_path]).to eq(output_dir)
        expect(result[:image_paths]).to include(
          "/tmp/tahweel_uuid/page_1.png",
          "/tmp/tahweel_uuid/page_2.png"
        )
      end
    end

    context "when running on Windows" do
      before do
        stub_const("RbConfig::CONFIG", { "host_os" => "mswin" })
      end

      it "skips the libvips installation check" do
        splitter.split
        expect(splitter).not_to have_received(:system).with(/vips --version/, any_args)
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

    context "when libvips is not installed (on non-Windows)" do
      before do
        allow(splitter).to receive(:system).with(/vips --version/, any_args).and_return(false)
      end

      it "aborts execution" do
        expect { splitter.split }.to raise_error(SystemExit, /libvips is not installed/)
      end
    end

    context "when Vips throws an error" do
      before do
        allow(Vips::Image).to receive(:pdfload).and_raise(Vips::Error, "Corrupt PDF")
      end

      it "propagates the Vips error" do
        expect { splitter.split }.to raise_error(Vips::Error, "Corrupt PDF")
      end
    end
  end
end
