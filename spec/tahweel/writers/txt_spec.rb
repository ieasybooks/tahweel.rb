# frozen_string_literal: true

require "spec_helper"
require "tahweel/writers/txt"

RSpec.describe Tahweel::Writers::Txt do
  subject(:writer) { described_class.new }

  let(:texts) { ["Page 1 content", "Page 2 content"] }
  let(:destination) { "output.txt" }

  before do
    allow(File).to receive(:write)
  end

  describe "#extension" do
    it "returns 'txt'" do
      expect(writer.extension).to eq("txt")
    end
  end

  describe "#write" do
    it "writes the joined texts to the destination file" do
      writer.write(texts, destination)

      expected_content = "Page 1 content\n\nPAGE_SEPARATOR\n\nPage 2 content"
      expect(File).to have_received(:write).with(destination, expected_content)
    end

    it "uses custom page separator" do
      writer.write(texts, destination, page_separator: "---")

      expected_content = "Page 1 content---Page 2 content"
      expect(File).to have_received(:write).with(destination, expected_content)
    end
  end
end
