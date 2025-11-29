# frozen_string_literal: true

require "spec_helper"
require "tahweel/converter"

RSpec.describe Tahweel::Converter do
  subject(:converter) { described_class.new(pdf_path) }

  let(:pdf_path) { "test.pdf" }
  let(:temp_dir) { "/tmp/tahweel_test" }
  let(:image_paths) { ["/tmp/tahweel_test/page_1.png", "/tmp/tahweel_test/page_2.png"] }
  let(:split_result) { { folder_path: temp_dir, image_paths: image_paths } }
  let(:ocr_engine) { instance_double(Tahweel::Ocr) }

  before do
    # Mock PdfSplitter
    allow(Tahweel::PdfSplitter).to receive(:split).with(pdf_path, dpi: 150).and_return(split_result)

    # Mock Ocr
    allow(Tahweel::Ocr).to receive(:new).with(processor: :google_drive).and_return(ocr_engine)
    allow(ocr_engine).to receive(:extract).with(image_paths[0]).and_return("Page 1 Text")
    allow(ocr_engine).to receive(:extract).with(image_paths[1]).and_return("Page 2 Text")

    # Mock FileUtils
    allow(FileUtils).to receive(:rm_rf)
  end

  describe ".convert" do
    it "instantiates the converter and calls convert" do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:convert).and_return(["Text"])

      described_class.convert(pdf_path)

      expect(described_class).to have_received(:new).with(
        pdf_path,
        dpi: 150,
        processor: :google_drive,
        concurrency: Tahweel::Converter::DEFAULT_CONCURRENCY
      )
      expect(instance).to have_received(:convert)
    end
  end

  describe "#convert" do
    it "orchestrates the conversion process successfully" do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      result = converter.convert

      expect(Tahweel::PdfSplitter).to have_received(:split).with(pdf_path, dpi: 150)
      expect(ocr_engine).to have_received(:extract).with(image_paths[0])
      expect(ocr_engine).to have_received(:extract).with(image_paths[1])
      expect(FileUtils).to have_received(:rm_rf).with(temp_dir)
      expect(result).to eq(["Page 1 Text", "Page 2 Text"])
    end

    context "when processing fails" do
      before do
        allow(converter).to receive(:process_images_concurrently).and_raise(RuntimeError, "OCR Error") # rubocop:disable RSpec/SubjectStub
      end

      it "ensures the temporary directory is cleaned up" do # rubocop:disable RSpec/MultipleExpectations
        expect { converter.convert }.to raise_error(RuntimeError, "OCR Error")
        expect(FileUtils).to have_received(:rm_rf).with(temp_dir)
      end
    end

    context "with custom options" do
      subject(:converter) { described_class.new(pdf_path, dpi: 300, processor: :custom, concurrency: 5) }

      before do
        allow(Tahweel::PdfSplitter).to receive(:split).with(pdf_path, dpi: 300).and_return(split_result)
        allow(Tahweel::Ocr).to receive(:new).with(processor: :custom).and_return(ocr_engine)
      end

      it "passes custom options to dependencies" do # rubocop:disable RSpec/MultipleExpectations
        converter.convert

        expect(Tahweel::PdfSplitter).to have_received(:split).with(pdf_path, dpi: 300)
        expect(Tahweel::Ocr).to have_received(:new).with(processor: :custom)
      end

      it "uses the custom concurrency limit" do
        # We need to spy on Async::Semaphore to verify the limit
        allow(Async::Semaphore).to receive(:new).and_call_original
        converter.convert
        expect(Async::Semaphore).to have_received(:new).with(5, parent: anything)
      end
    end
  end
end
