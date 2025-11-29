# frozen_string_literal: true

require "spec_helper"
require "tahweel/cli/file_collector"

RSpec.describe Tahweel::CLI::FileCollector do
  describe ".collect" do
    context "when input path is a file" do
      it "returns the file path in an array" do
        allow(File).to receive(:directory?).and_return(false)
        expect(described_class.collect("file.pdf")).to eq(["file.pdf"])
      end
    end

    context "when input path is a directory" do
      let(:input_dir) { "/path/to/dir" }

      before do
        allow(File).to receive(:directory?).with(input_dir).and_return(true)
      end

      it "globs for supported extensions recursively by default" do # rubocop:disable RSpec/MultipleExpectations
        expected_glob = "/path/to/dir/**/*.{pdf,jpg,jpeg,png}"
        allow(Dir).to receive(:glob).with(expected_glob, File::FNM_CASEFOLD).and_return(["file1.pdf", "file2.jpg"])

        result = described_class.collect(input_dir)

        expect(Dir).to have_received(:glob).with(expected_glob, File::FNM_CASEFOLD)
        expect(result).to eq(["file1.pdf", "file2.jpg"])
      end

      it "globs for specified extensions when provided" do # rubocop:disable RSpec/MultipleExpectations
        expected_glob = "/path/to/dir/**/*.{txt,md}"
        allow(Dir).to receive(:glob).with(expected_glob, File::FNM_CASEFOLD).and_return(["file.txt"])

        result = described_class.collect(input_dir, extensions: %w[txt md])

        expect(Dir).to have_received(:glob).with(expected_glob, File::FNM_CASEFOLD)
        expect(result).to eq(["file.txt"])
      end

      it "sorts the results" do
        allow(Dir).to receive(:glob).and_return(["b.pdf", "a.pdf"])
        expect(described_class.collect(input_dir)).to eq(["a.pdf", "b.pdf"])
      end
    end
  end
end
