# frozen_string_literal: true

require "spec_helper"
require "tahweel/writers/json"

RSpec.describe Tahweel::Writers::Json do
  subject(:writer) { described_class.new }

  let(:texts) { ["Page 1 content", "Page 2 content"] }
  let(:destination) { "output.json" }

  before do
    allow(File).to receive(:write)
  end

  describe "#extension" do
    it "returns 'json'" do
      expect(writer.extension).to eq("json")
    end
  end

  describe "#write" do
    it "writes the texts as structured JSON to the destination file" do # rubocop:disable RSpec/ExampleLength
      writer.write(texts, destination)

      expected_data = [
        { page: 1, content: "Page 1 content" },
        { page: 2, content: "Page 2 content" }
      ]
      expected_content = JSON.pretty_generate(expected_data)
      expect(File).to have_received(:write).with(destination, expected_content)
    end
  end
end
