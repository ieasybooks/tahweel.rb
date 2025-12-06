# frozen_string_literal: true

require "spec_helper"

RSpec.describe Tahweel::PopplerInstaller do
  let(:installer) { described_class.new }
  let(:cache_dir) { "/tmp/cache/tahweel/poppler" }
  let(:zip_path) { File.join(cache_dir, "Release-23.01.0-0.zip") }
  let(:poppler_root) { File.join(cache_dir, "poppler-23.01.0") }
  let(:bin_path) { File.join(poppler_root, "Library", "bin") }

  before do
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:rm_f)
    allow(XDG::Cache).to receive(:new).and_return(double(home: Pathname.new("/tmp/cache")))
    allow(Dir).to receive(:home).and_return("/tmp")
  end

  describe ".ensure_installed!" do
    context "when already installed" do
      it "returns immediately without installing or aborting" do
        instance = instance_spy(described_class, installed?: true)
        allow(described_class).to receive(:new).and_return(instance)

        described_class.ensure_installed!

        expect(instance).not_to have_received(:install)
      end
    end

    context "when on Windows" do
      before do
        allow(Gem).to receive(:win_platform?).and_return(true)
      end

      it "installs poppler" do
        expect_any_instance_of(described_class).to receive(:install) # rubocop:disable RSpec/AnyInstance
        described_class.ensure_installed!
      end
    end

    context "when on non-Windows" do
      before do
        allow(Gem).to receive(:win_platform?).and_return(false)
      end

      it "aborts with instructions" do
        instance = instance_double(described_class, installed?: false)
        allow(described_class).to receive(:new).and_return(instance)
        expect { described_class.ensure_installed! }.to raise_error(SystemExit).and output(/install poppler/).to_stderr
      end
    end
  end

  describe ".pdftoppm_path" do
    it "delegates to instance method" do
      expect_any_instance_of(described_class).to receive(:pdftoppm_path) # rubocop:disable RSpec/AnyInstance
      described_class.pdftoppm_path
    end
  end

  describe ".pdfinfo_path" do
    it "delegates to instance method" do
      expect_any_instance_of(described_class).to receive(:pdfinfo_path) # rubocop:disable RSpec/AnyInstance
      described_class.pdfinfo_path
    end
  end

  describe "#install" do
    before do
      allow(installer).to receive_messages(installed?: false, download_release_file: zip_path)
      allow(installer).to receive(:extract_zip_file)
    end

    it "downloads and extracts if not installed" do # rubocop:disable RSpec/MultipleExpectations
      installer.install
      expect(installer).to have_received(:download_release_file)
      expect(installer).to have_received(:extract_zip_file).with(zip_path)
    end

    it "removes zip file after installation" do
      installer.install
      expect(FileUtils).to have_received(:rm_f).with(zip_path)
    end

    it "does nothing if already installed" do
      allow(installer).to receive(:installed?).and_return(true)
      installer.install
      expect(installer).not_to have_received(:download_release_file)
    end
  end

  describe "#installed?" do
    before do
      allow(installer).to receive(:cached?).and_return(false)
    end

    it "returns true if commands exist" do
      allow(installer).to receive(:command_exists?).with("pdftoppm").and_return(true)
      allow(installer).to receive(:command_exists?).with("pdfinfo").and_return(true)
      expect(installer).to be_installed
    end

    it "returns true if cached" do
      allow(installer).to receive_messages(command_exists?: false, cached?: true)
      expect(installer).to be_installed
    end

    it "returns false if neither exist" do
      allow(installer).to receive(:command_exists?).and_return(false)
      expect(installer).not_to be_installed
    end
  end

  describe "#cached?" do
    context "when on Windows" do
      before do
        allow(Gem).to receive(:win_platform?).and_return(true)
        allow(Dir).to receive(:glob).and_return([poppler_root])
      end

      it "returns true if pdftoppm.exe exists in cache" do
        allow(File).to receive(:exist?).with(File.join(bin_path, "pdftoppm.exe")).and_return(true)
        expect(installer).to be_cached
      end

      it "returns false if pdftoppm.exe does not exist" do
        allow(File).to receive(:exist?).with(File.join(bin_path, "pdftoppm.exe")).and_return(false)
        expect(installer).not_to be_cached
      end
    end

    context "when on non-Windows" do
      before do
        allow(Gem).to receive(:win_platform?).and_return(false)
      end

      it "returns false" do
        expect(installer).not_to be_cached
      end
    end
  end

  describe "#pdftoppm_path" do
    it "returns 'pdftoppm' if command exists" do
      allow(installer).to receive(:command_exists?).with("pdftoppm").and_return(true)
      expect(installer.pdftoppm_path).to eq("pdftoppm")
    end

    it "returns cached path if command does not exist and on Windows" do
      allow(Gem).to receive(:win_platform?).and_return(true)
      allow(installer).to receive(:command_exists?).with("pdftoppm").and_return(false)
      allow(Dir).to receive(:glob).and_return([poppler_root])
      expect(installer.pdftoppm_path).to eq(File.join(bin_path, "pdftoppm.exe"))
    end

    it "returns nil if command does not exist and not on Windows" do
      allow(Gem).to receive(:win_platform?).and_return(false)
      allow(installer).to receive(:command_exists?).with("pdftoppm").and_return(false)
      expect(installer.pdftoppm_path).to be_nil
    end
  end

  describe "#pdfinfo_path" do
    it "returns 'pdfinfo' if command exists" do
      allow(installer).to receive(:command_exists?).with("pdfinfo").and_return(true)
      expect(installer.pdfinfo_path).to eq("pdfinfo")
    end

    it "returns cached path if command does not exist and on Windows" do
      allow(Gem).to receive(:win_platform?).and_return(true)
      allow(installer).to receive(:command_exists?).with("pdfinfo").and_return(false)
      allow(Dir).to receive(:glob).and_return([poppler_root])
      expect(installer.pdfinfo_path).to eq(File.join(bin_path, "pdfinfo.exe"))
    end

    it "returns nil if command does not exist and not on Windows" do
      allow(Gem).to receive(:win_platform?).and_return(false)
      allow(installer).to receive(:command_exists?).with("pdfinfo").and_return(false)
      expect(installer.pdfinfo_path).to be_nil
    end
  end

  describe "private methods" do
    # Testing private methods via send or public triggers where possible,
    # but given the complexity of download_release_file, we might want to unit test it
    # by allowing access or just relying on the integration flow in #install.
    # However, #install mocks it. Let's test the actual downloading logic separately.

    describe "#cached_bin_path (via private access)" do
      it "returns empty string if no poppler directory found" do
        allow(Dir).to receive(:glob).and_return([])
        expect(installer.send(:cached_bin_path)).to eq("")
      end
    end

    describe "#latest_release_url (via private access)" do
      before do
        uri = URI(Tahweel::PopplerInstaller::POPPLER_REPO_API)
        allow(URI).to receive(:parse).with(Tahweel::PopplerInstaller::POPPLER_REPO_API).and_return(uri)
      end

      it "aborts if API request fails" do # rubocop:disable RSpec/ExampleLength
        stub_request_obj = instance_double(Net::HTTP::Get)
        allow(Net::HTTP::Get).to receive(:new).and_return(stub_request_obj)
        allow(stub_request_obj).to receive(:[]=)

        http_response = instance_double(Net::HTTPNotFound, is_a?: false, code: "404", message: "Not Found")
        allow(Net::HTTP).to receive(:start).and_yield(double(request: http_response))

        expect do
          installer.send(:latest_release_url)
        end.to raise_error(SystemExit, /Failed to fetch Poppler release info/)
      end

      it "aborts if no valid asset found" do # rubocop:disable RSpec/ExampleLength
        stub_request_obj = instance_double(Net::HTTP::Get)
        allow(Net::HTTP::Get).to receive(:new).and_return(stub_request_obj)
        allow(stub_request_obj).to receive(:[]=)

        response_body = { "assets" => [{ "name" => "invalid_file.txt" }] }.to_json
        http_response = instance_double(Net::HTTPSuccess, is_a?: true, body: response_body)
        allow(Net::HTTP).to receive(:start).and_yield(double(request: http_response))

        expect { installer.send(:latest_release_url) }.to raise_error(SystemExit, /No valid Windows release found/)
      end
    end

    describe "#cache_dir (via private access)" do
      it "falls back to ~/.cache if XDG cache home is empty" do
        allow(XDG::Cache).to receive(:new).and_return(double(home: double(to_s: "")))
        allow(Dir).to receive(:home).and_return("/home/user")

        expect(installer.send(:cache_dir)).to eq(File.join("/home/user", ".cache", "tahweel", "poppler"))
      end
    end

    describe "#download_release_file (via send)" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:release_url) { "https://github.com/oschwartz10612/poppler-windows/releases/download/v23.01.0-0/Release-23.01.0-0.zip" }
      let(:response_body) do
        {
          "assets" => [
            { "name" => "Release-23.01.0-0.zip", "browser_download_url" => release_url }
          ]
        }.to_json
      end

      before do
        # Mock GitHub API response
        stub_request_obj = instance_double(Net::HTTP::Get)
        allow(Net::HTTP::Get).to receive(:new).and_return(stub_request_obj)
        allow(stub_request_obj).to receive(:[]=).with("User-Agent", "Tahweel-Gem")

        http_response = instance_double(Net::HTTPSuccess, body: response_body, is_a?: true)
        allow(Net::HTTP).to receive(:start).and_yield(double(request: http_response))

        # Mock URI open
        io_double = instance_double(IO)
        allow(io_double).to receive(:read).and_return("zip_content")
        allow(URI).to receive(:parse).with(release_url).and_return(double("URI", open: nil)) # rubocop:disable RSpec/VerifiedDoubles
        allow(URI.parse(release_url)).to receive(:open).and_yield(io_double)

        # Allow URI parsing for the API endpoint as well, returning a real URI object or double that works with Net::HTTP
        allow(URI).to receive(:parse).with(Tahweel::PopplerInstaller::POPPLER_REPO_API).and_call_original
        allow(File).to receive(:binwrite)
      end

      it "fetches release url and downloads file" do
        installer.send(:download_release_file)
        expect(File).to have_received(:binwrite).with(zip_path, "zip_content")
      end
    end

    describe "#extract_zip_file (via send)" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:mock_zip_file) { instance_double(Zip::File) }
      let(:mock_entry) { double(name: "test/file.txt") }

      before do
        allow(Zip::File).to receive(:open).with(zip_path).and_yield(mock_zip_file)
        allow(mock_zip_file).to receive(:each).and_yield(mock_entry)
        allow(mock_zip_file).to receive(:extract)
      end

      it "extracts entries" do
        installer.send(:extract_zip_file, zip_path)
        expect(mock_zip_file).to have_received(:extract).with(mock_entry, File.join(cache_dir, "test/file.txt"))
      end
    end

    describe "#command_exists? (via send)" do
      context "when on Windows" do # rubocop:disable RSpec/NestedGroups
        before { allow(Gem).to receive(:win_platform?).and_return(true) }

        it "uses 'where'" do
          allow(installer).to receive(:system).with("where test > #{File::NULL} 2>&1")
          installer.send(:command_exists?, "test")
          expect(installer).to have_received(:system).with("where test > #{File::NULL} 2>&1")
        end
      end

      context "when on Unix" do # rubocop:disable RSpec/NestedGroups
        before { allow(Gem).to receive(:win_platform?).and_return(false) }

        it "uses 'which'" do
          allow(installer).to receive(:system).with("which test > #{File::NULL} 2>&1")
          installer.send(:command_exists?, "test")
          expect(installer).to have_received(:system).with("which test > #{File::NULL} 2>&1")
        end
      end
    end
  end
end
