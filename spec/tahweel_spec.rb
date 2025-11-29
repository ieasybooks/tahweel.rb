# frozen_string_literal: true

require "spec_helper"

RSpec.describe Tahweel do
  it "has a version number" do
    expect(Tahweel::VERSION).not_to be_nil
  end

  describe ".convert" do
    it "delegates to Tahweel::Converter.convert" do # rubocop:disable RSpec/MultipleExpectations
      allow(Tahweel::Converter).to receive(:convert).and_return(["Text"])

      result = described_class.convert("test.pdf", dpi: 300, processor: :custom)

      expect(result).to eq(["Text"])
      expect(Tahweel::Converter).to have_received(:convert).with(
        "test.pdf",
        dpi: 300,
        processor: :custom
      )
    end

    it "uses default values when optional arguments are omitted" do
      allow(Tahweel::Converter).to receive(:convert).and_return(["Text"])

      described_class.convert("test.pdf")

      expect(Tahweel::Converter).to have_received(:convert).with(
        "test.pdf",
        dpi: Tahweel::PdfSplitter::DEFAULT_DPI,
        processor: :google_drive
      )
    end
  end
end
