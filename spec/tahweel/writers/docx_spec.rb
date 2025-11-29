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

      expect(mock_docx).to have_received(:p).with("Page 1 content", hash_including(align: :left))
      expect(mock_docx).to have_received(:p).with("Page\n2\tcontent", hash_including(align: :left))

      # It should add a page break after each text block EXCEPT the last one
      expect(mock_docx).to have_received(:page).exactly(dirty_texts.size - 1).times
    end

    it "aligns arabic text to the right" do # rubocop:disable RSpec/ExampleLength
      mock_docx = double("CaracalDocument") # rubocop:disable RSpec/VerifiedDoubles
      allow(Caracal::Document).to receive(:save).and_yield(mock_docx)
      allow(mock_docx).to receive(:p)
      allow(mock_docx).to receive(:page)

      arabic_text = "مرحبا بكم"
      writer.write([arabic_text], destination)

      expect(mock_docx).to have_received(:p).with(arabic_text, hash_including(align: :right))
    end

    it "aligns mixed text based on majority characters" do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      mock_docx = double("CaracalDocument") # rubocop:disable RSpec/VerifiedDoubles
      allow(Caracal::Document).to receive(:save).and_yield(mock_docx)
      allow(mock_docx).to receive(:p)
      allow(mock_docx).to receive(:page)

      # More Arabic chars
      mixed_arabic = "مرحبا hello"
      writer.write([mixed_arabic], destination)
      expect(mock_docx).to have_received(:p).with(mixed_arabic, hash_including(align: :right))

      # More Latin chars
      mixed_english = "hello مرحب"
      writer.write([mixed_english], destination)
      expect(mock_docx).to have_received(:p).with(mixed_english, hash_including(align: :left))
    end

    it "merges short lines to fit within page limits" do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      mock_docx = double("CaracalDocument") # rubocop:disable RSpec/VerifiedDoubles
      allow(Caracal::Document).to receive(:save).and_yield(mock_docx)
      allow(mock_docx).to receive(:p)
      allow(mock_docx).to receive(:page)

      # Construct a text that would trigger merging (many short lines)
      # We need enough lines so that expected_lines_in_page > 40
      # 45 lines of "a"
      many_short_lines = Array.new(45, "a").join("\n")

      writer.write([many_short_lines], destination)

      # We expect the text passed to docx.p to have fewer lines than the original
      # because compact_shortest_lines should have been called repeatedly
      expect(mock_docx).to have_received(:p) do |text, _options|
        expect(text.count("\n")).to be < 41
      end
    end

    it "merges lines with minimum combined length" do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      mock_docx = double("CaracalDocument") # rubocop:disable RSpec/VerifiedDoubles
      allow(Caracal::Document).to receive(:save).and_yield(mock_docx)
      allow(mock_docx).to receive(:p)
      allow(mock_docx).to receive(:page)

      # Lines with lengths: 5, 3, 14, 1
      # Sums: (5+3)=8, (3+14)=17, (14+1)=15
      # Minimum is 8 (lines 1 and 2)
      text = "aaaaa\nbbb\ncccccccccccccc\nd"

      # Force expected_lines_in_page to return > 40 so merge runs once
      # We can do this by stubbing the method on the instance
      allow(writer).to receive(:expected_lines_in_page).and_return(41, 0) # rubocop:disable RSpec/SubjectStub

      writer.write([text], destination)

      expect(mock_docx).to have_received(:p) do |merged_text, _options|
        # Expect lines 1 and 2 merged: "aaaaa bbb"
        expected = "aaaaa bbb\ncccccccccccccc\nd"
        expect(merged_text).to eq(expected)
      end
    end

    it "does not merge lines if there are fewer than 2 lines" do # rubocop:disable RSpec/ExampleLength
      mock_docx = double("CaracalDocument") # rubocop:disable RSpec/VerifiedDoubles
      allow(Caracal::Document).to receive(:save).and_yield(mock_docx)
      allow(mock_docx).to receive(:p)
      allow(mock_docx).to receive(:page)

      # Force expected_lines_in_page to trigger the loop, but compact_shortest_lines should return immediately
      allow(writer).to receive(:expected_lines_in_page).and_return(41, 0) # rubocop:disable RSpec/SubjectStub

      single_line_text = "Just one line"
      writer.write([single_line_text], destination)

      expect(mock_docx).to have_received(:p).with(single_line_text, anything)
    end
  end
end
