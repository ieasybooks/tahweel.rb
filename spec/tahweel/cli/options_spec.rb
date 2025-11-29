# frozen_string_literal: true

require "spec_helper"
require "tahweel/cli/options"

RSpec.describe Tahweel::CLI::Options do
  describe ".parse" do
    subject(:parsed_options) { described_class.parse(args) }

    let(:args) { [] }

    context "when no arguments are provided" do
      it "exits with status 1 and prints help" do # rubocop:disable RSpec/MultipleExpectations
        expect { described_class.parse([]) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context "when valid arguments are provided" do
      let(:args) { ["file.pdf", "--dpi", "300", "--concurrency", "5"] }

      it "parses options correctly" do # rubocop:disable RSpec/MultipleExpectations
        expect(parsed_options[:dpi]).to eq(300)
        expect(parsed_options[:concurrency]).to eq(5)
      end

      it "retains default values for unspecified options" do # rubocop:disable RSpec/MultipleExpectations
        expect(parsed_options[:processor]).to eq(:google_drive)
        expect(parsed_options[:formats]).to eq([:txt])
      end
    end

    context "when all options are explicitly provided" do
      let(:args) do
        [
          "file.pdf",
          "--processor", "google_drive",
          "--output", "/tmp/output",
          "--formats", "txt,json"
        ]
      end

      it "parses processor correctly" do
        expect(parsed_options[:processor]).to eq(:google_drive)
      end

      it "parses output directory correctly" do
        expect(parsed_options[:output]).to eq("/tmp/output")
      end

      it "parses and validates formats correctly" do
        expect(parsed_options[:formats]).to eq(%i[txt json])
      end
    end

    context "when invalid options are provided" do
      let(:args) { ["file.pdf", "--invalid-option"] }

      it "aborts with an error message" do
        expect do
          described_class.parse(args)
        end.to raise_error(SystemExit).and output(/Error: invalid option: --invalid-option/).to_stderr
      end
    end

    context "when invalid format is provided" do
      let(:args) { ["file.pdf", "--formats", "invalid_format"] }

      it "aborts with an error message" do
        expect do
          described_class.parse(args)
        end.to raise_error(SystemExit).and output(/Error: Invalid format\(s\): invalid_format/).to_stderr
      end
    end

    context "when help option is provided" do
      let(:args) { ["--help"] }

      it "prints help and exits successfully" do # rubocop:disable RSpec/MultipleExpectations
        expect { described_class.parse(args) }
          .to output(/Usage: tahweel/).to_stdout
          .and raise_error(SystemExit) { |error| expect(error.status).to eq(0) }
      end
    end

    context "when extensions are provided" do
      let(:args) { ["input_dir", "--extensions", "txt,md"] }

      it "parses extensions as an array" do
        expect(parsed_options[:extensions]).to eq(%w[txt md])
      end
    end

    context "when page separator is provided" do
      let(:args) { ["file.pdf", "--page-separator", "\\n---new-page---\\n"] }

      it "parses and unescapes the separator" do
        expect(parsed_options[:page_separator]).to eq("\n---new-page---\n")
      end
    end
  end
end
