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
    it "processes images concurrently using threads" do
      allow(Thread).to receive(:new).and_call_original
      converter.convert
      expect(Thread).to have_received(:new).exactly(Tahweel::Converter::DEFAULT_CONCURRENCY).times
    end

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
        allow(converter).to receive(:process_images).and_raise(RuntimeError, "OCR Error") # rubocop:disable RSpec/SubjectStub
      end

      it "ensures the temporary directory is cleaned up" do # rubocop:disable RSpec/MultipleExpectations
        expect { converter.convert }.to raise_error(RuntimeError, "OCR Error")
        expect(FileUtils).to have_received(:rm_rf).with(temp_dir)
      end
    end

    context "when a race condition occurs in the queue" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:queue) { instance_double(Queue) }

      before do
        allow(Queue).to receive(:new).and_return(queue)
        allow(queue).to receive(:<<)
        # Force entry into loop then raise error
        allow(queue).to receive(:empty?).and_return(false)
        allow(queue).to receive(:pop).with(true).and_raise(ThreadError)
      end

      it "handles ThreadError gracefully and terminates the worker" do
        expect { converter.convert }.not_to raise_error
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
    end

    context "when a block is provided for progress reporting" do
      it "yields progress for each processed page" do # rubocop:disable RSpec/MultipleExpectations
        expect { |b| converter.convert(&b) }.to yield_control.exactly(2).times

        # Since we can't guarantee order of thread execution, we check that both progress updates are received
        expect { |b| converter.convert(&b) }.to yield_successive_args(
          {
            file_path: pdf_path,
            stage: :ocr,
            current_page: 1,
            percentage: 50.0,
            remaining_pages: 1
          },
          {
            file_path: pdf_path,
            stage: :ocr,
            current_page: 2,
            percentage: 100.0,
            remaining_pages: 0
          }
        )
      end
    end
  end
end
