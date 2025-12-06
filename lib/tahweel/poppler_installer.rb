# frozen_string_literal: true

require "fileutils"
require "json"
require "net/http"
require "open-uri"
require "uri"
require "xdg"
require "zip"

module Tahweel
  # Handles the installation and path resolution for Poppler utilities.
  #
  # On Windows, this class can automatically download and install the necessary
  # binaries if they are not present. On other platforms, it provides instructions
  # for manual installation.
  class PopplerInstaller
    POPPLER_REPO_API = "https://api.github.com/repos/oschwartz10612/poppler-windows/releases/latest"

    # Ensures that Poppler utilities are installed.
    #
    # On Windows: Installs Poppler locally if not found.
    # On other platforms: Aborts with an error message if Poppler is missing.
    #
    # @raise [SystemExit] if Poppler is missing on non-Windows platforms.
    def self.ensure_installed! # rubocop:disable Metrics/MethodLength
      installer = new
      return if installer.installed?

      if Gem.win_platform?
        installer.install
      else
        abort <<~MSG
          Error: Poppler utilities are not installed. Please install them:
          MacOS:  `brew install poppler`
          Ubuntu: `sudo apt install poppler-utils`
        MSG
      end
    end

    # Returns the path to the `pdftoppm` executable.
    # @return [String] path to the executable.
    def self.pdftoppm_path = new.pdftoppm_path

    # Returns the path to the `pdfinfo` executable.
    # @return [String] path to the executable.
    def self.pdfinfo_path = new.pdfinfo_path

    # Installs Poppler binaries on Windows.
    #
    # Downloads the latest release from GitHub and extracts it to the cache directory.
    # Does nothing if already installed.
    def install
      zip_path = nil
      return if installed?

      zip_path = download_release_file
      extract_zip_file(zip_path)
    ensure
      FileUtils.rm_f(zip_path) if zip_path
    end

    # Checks if Poppler utilities are available.
    #
    # @return [Boolean] true if `pdftoppm` and `pdfinfo` are in the PATH or cached.
    def installed? = (command_exists?("pdftoppm") && command_exists?("pdfinfo")) || cached?

    # Checks if Poppler binaries are present in the local cache (Windows only).
    #
    # @return [Boolean] true if cached binaries exist.
    def cached?
      return false unless Gem.win_platform?

      File.exist?(File.join(cached_bin_path, "pdftoppm.exe"))
    end

    # Resolves the path to the `pdftoppm` executable.
    #
    # Prioritizes the system PATH, falling back to the cached version on Windows.
    #
    # @return [String] path to `pdftoppm`.
    def pdftoppm_path
      return "pdftoppm" if command_exists?("pdftoppm")

      Gem.win_platform? ? File.join(cached_bin_path, "pdftoppm.exe") : nil
    end

    # Resolves the path to the `pdfinfo` executable.
    #
    # Prioritizes the system PATH, falling back to the cached version on Windows.
    #
    # @return [String] path to `pdfinfo`.
    def pdfinfo_path
      return "pdfinfo" if command_exists?("pdfinfo")

      Gem.win_platform? ? File.join(cached_bin_path, "pdfinfo.exe") : nil
    end

    private

    # Locates the `bin` directory within the cached Poppler installation.
    #
    # Searches for a directory matching "poppler-*" in the cache directory and returns
    # the path to its `Library/bin` subdirectory.
    #
    # @return [String] Path to the `bin` directory, or an empty string if not found.
    def cached_bin_path
      poppler_root = Dir.glob(File.join(cache_dir, "poppler-*")).first
      return "" unless poppler_root

      File.join(poppler_root, "Library", "bin")
    end

    # Checks if a command is available in the system path.
    #
    # @param cmd [String] The command to check for.
    # @return [Boolean] true if the command exists in the PATH.
    def command_exists?(cmd)
      Gem.win_platform? ? system("where #{cmd} > NUL 2>&1") : system("which #{cmd} > /dev/null 2>&1")
    end

    # Downloads the latest Poppler release zip file.
    #
    # Fetches the download URL from the GitHub API and saves the file to the cache directory.
    #
    # @return [String] The local path to the downloaded zip file.
    def download_release_file
      release_url = latest_release_url
      zip_path = File.join(cache_dir, File.basename(release_url))
      URI.parse(release_url).open { File.binwrite(zip_path, _1.read) }
    end

    # Retrieves the download URL for the latest Windows release of Poppler.
    #
    # Queries the GitHub API for the latest release and finds the asset matching "Release*.zip".
    #
    # @return [String] The download URL of the asset.
    # @raise [SystemExit] if the API request fails or no valid asset is found.
    def latest_release_url # rubocop:disable Metrics/AbcSize
      uri = URI(POPPLER_REPO_API)
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "Tahweel-Gem"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { _1.request(request) }

      unless response.is_a?(Net::HTTPSuccess)
        abort "Failed to fetch Poppler release info: #{response.code} #{response.message}"
      end

      asset = JSON.parse(response.body)["assets"].find { _1["name"].match?(/^Release.*\.zip$/) }

      asset ? asset["browser_download_url"] : abort("No valid Windows release found for Poppler.")
    end

    # Extracts the downloaded zip file to the cache directory.
    #
    # @param zip_path [String] Path to the zip file to extract.
    def extract_zip_file(zip_path)
      Zip::File.open(zip_path) do |zip_file|
        zip_file.each do |entry|
          entry_dest = File.join(cache_dir, entry.name)
          FileUtils.mkdir_p(File.dirname(entry_dest))
          zip_file.extract(entry, entry_dest) { true }
        end
      end
    end

    # Resolves the directory used for caching downloaded binaries.
    #
    # Uses the XDG cache home directory if available, otherwise defaults to `~/.cache/tahweel/poppler`.
    #
    # @return [String] Path to the cache directory.
    def cache_dir
      base = XDG.new.cache_home.to_s
      base = File.join(Dir.home, ".cache") if base.empty?

      dir = File.join(base, "tahweel", "poppler")
      FileUtils.mkdir_p(dir)
      dir
    end
  end
end
