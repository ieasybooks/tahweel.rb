# frozen_string_literal: true

require "spec_helper"
require "tahweel/writers/docx"
require "caracal"

RSpec.describe Tahweel::Writers::Docx do
  subject(:writer) { described_class.new }

  let(:texts) { ["Page 1 content", "Page 2 content"] }
  let(:destination) { "output.docx" }

  describe "#extension" do
    it "returns 'docx'" do
      expect(writer.extension).to eq("docx")
    end
  end

  describe "#write" do
    it "creates a new Caracal document and saves it with cleaned text" do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      mock_docx = double("CaracalDocument") # rubocop:disable RSpec/VerifiedDoubles
      allow(Caracal::Document).to receive(:save).and_yield(mock_docx)
      allow(mock_docx).to receive(:p)
      allow(mock_docx).to receive(:page)

      dirty_texts = ["Page  1   content", "Page\r\n\r\n2\t\tcontent"]
      writer.write(dirty_texts, destination)

      expect(Caracal::Document).to have_received(:save).with(destination)

      expect(mock_docx).to have_received(:p).with("Page 1 content")
      expect(mock_docx).to have_received(:p).with("Page\n2\tcontent")

      # It should add a page break after each text block EXCEPT the last one
      expect(mock_docx).to have_received(:page).exactly(dirty_texts.size - 1).times
    end
  end
end
