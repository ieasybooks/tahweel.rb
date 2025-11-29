# frozen_string_literal: true

require "spec_helper"
require "tahweel/writer"

RSpec.describe Tahweel::Writer do
  let(:texts) { ["Text"] }
  let(:base_path) { "output" }
  let(:mock_txt_writer) { instance_double(Tahweel::Writers::Txt) }

  before do
    allow(Tahweel::Writers::Txt).to receive(:new).and_return(mock_txt_writer)
    allow(mock_txt_writer).to receive(:write)
    allow(mock_txt_writer).to receive(:extension).and_return("txt")
  end

  describe ".write" do
    it "instantiates a new Writer and delegates to #write for each format" do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:write)

      described_class.write(texts, base_path, formats: [:txt])

      expect(described_class).to have_received(:new).with(format: :txt)
      expect(instance).to have_received(:write).with(texts, base_path)
    end
  end

  describe "#initialize" do
    it "initializes with :txt writer by default" do
      writer = described_class.new
      expect(writer.instance_variable_get(:@writer)).to eq(mock_txt_writer)
    end

    it "initializes with :txt writer explicitly" do
      described_class.new(format: :txt)
      expect(Tahweel::Writers::Txt).to have_received(:new)
    end

    it "raises ArgumentError for unknown formats" do
      expect { described_class.new(format: :unknown) }.to raise_error(ArgumentError, "Unknown format: unknown")
    end
  end

  describe "#write" do
    it "appends extension and delegates writing to the configured writer" do
      writer = described_class.new(format: :txt)
      writer.write(texts, base_path, option: "value")
      expect(mock_txt_writer).to have_received(:write).with(texts, "output.txt", { option: "value" })
    end
  end
end
