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
    let(:mock_docx) { double("CaracalDocument") } # rubocop:disable RSpec/VerifiedDoubles
    let(:mock_paragraph) { double("ParagraphModel") } # rubocop:disable RSpec/VerifiedDoubles
    let(:paragraph_calls) { [] }

    before do
      allow(Caracal::Document).to receive(:save).and_yield(mock_docx)
      allow(mock_docx).to receive(:p) do |options, &block|
        paragraph_calls << { options: options }
        # Simulate Caracal's instance_eval behavior
        mock_paragraph.instance_eval(&block) if block
      end
      allow(mock_docx).to receive(:page)
      allow(mock_paragraph).to receive(:text) { |content, _opts|
        paragraph_calls.last[:texts] ||= []
        paragraph_calls.last[:texts] << content
      }
      allow(mock_paragraph).to receive(:br) {
        paragraph_calls.last[:br_count] ||= 0
        paragraph_calls.last[:br_count] += 1
      }
    end

    it "creates a new Caracal document and saves it" do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      dirty_texts = ["Page  1   content", "Page\r\n\r\n2\t\tcontent"]
      writer.write(dirty_texts, destination)

      expect(Caracal::Document).to have_received(:save).with(destination)
      expect(paragraph_calls.size).to eq(2)
      expect(paragraph_calls[0][:options]).to include(align: :left)
      expect(paragraph_calls[1][:options]).to include(align: :left)

      # It should add a page break after each text block EXCEPT the last one
      expect(mock_docx).to have_received(:page).exactly(dirty_texts.size - 1).times
    end

    it "uses proper OOXML line breaks via br method for multi-line text" do # rubocop:disable RSpec/MultipleExpectations
      multi_line_text = "Line 1\nLine 2\nLine 3"
      writer.write([multi_line_text], destination)

      # Should call text for each line
      expect(paragraph_calls.first[:texts]).to eq(["Line 1", "Line 2", "Line 3"])

      # Should call br between lines (n-1 times for n lines)
      expect(paragraph_calls.first[:br_count]).to eq(2)
    end

    it "normalizes various line ending formats to proper breaks" do
      # Test \r\n (Windows) and \r (old Mac) - consecutive newlines are collapsed
      mixed_endings = "Line 1\r\nLine 2\rLine 3"
      writer.write([mixed_endings], destination)

      expect(paragraph_calls.first[:texts]).to eq(["Line 1", "Line 2", "Line 3"])
    end

    it "aligns arabic text to the right" do
      arabic_text = "مرحبا بكم"
      writer.write([arabic_text], destination)

      expect(paragraph_calls.first[:options]).to include(align: :right)
    end

    it "aligns mixed text based on majority characters" do # rubocop:disable RSpec/MultipleExpectations,RSpec/ExampleLength
      # More Arabic chars
      mixed_arabic = "مرحبا hello"
      writer.write([mixed_arabic], destination)
      expect(paragraph_calls.first[:options]).to include(align: :right)

      paragraph_calls.clear

      # More Latin chars
      mixed_english = "hello مرحب"
      writer.write([mixed_english], destination)
      expect(paragraph_calls.first[:options]).to include(align: :left)
    end

    it "merges short lines to fit within page limits" do
      # Construct a text that would trigger merging (many short lines)
      # We need enough lines so that expected_lines_in_page > 40
      # 45 lines of "a"
      many_short_lines = Array.new(45, "a").join("\n")

      writer.write([many_short_lines], destination)

      # After compaction, we should have fewer br calls than original line count - 1
      # Original would be 44 br calls (45 lines - 1)
      # After compaction to <= 40 lines, should be < 40 br calls
      expect(paragraph_calls.first[:br_count]).to be < 40
    end

    it "merges lines with minimum combined length" do # rubocop:disable RSpec/MultipleExpectations
      # Lines with lengths: 5, 3, 14, 1
      # Sums: (5+3)=8, (3+14)=17, (14+1)=15
      # Minimum is 8 (lines 1 and 2), so they get merged
      text = "aaaaa\nbbb\ncccccccccccccc\nd"

      # Force expected_lines_in_page to return > 40 so merge runs once
      allow(writer).to receive(:expected_lines_in_page).and_return(41, 0) # rubocop:disable RSpec/SubjectStub

      writer.write([text], destination)

      # After merge, should have: "aaaaa bbb", "cccccccccccccc", "d"
      expect(paragraph_calls.first[:texts]).to eq(["aaaaa bbb", "cccccccccccccc", "d"])
      expect(paragraph_calls.first[:br_count]).to eq(2)
    end

    it "does not merge lines if there are fewer than 2 lines" do # rubocop:disable RSpec/MultipleExpectations
      # Force expected_lines_in_page to trigger the loop, but compact_shortest_lines should return immediately
      allow(writer).to receive(:expected_lines_in_page).and_return(41, 0) # rubocop:disable RSpec/SubjectStub

      single_line_text = "Just one line"
      writer.write([single_line_text], destination)

      expect(paragraph_calls.first[:texts]).to eq([single_line_text])
      expect(paragraph_calls.first[:br_count]).to be_nil
    end
  end
end
