# frozen_string_literal: true

require "google/apis/drive_v3"
require "googleauth"
require "googleauth/stores/file_token_store"
require "socket"
require "uri"
require "launchy"
require "fileutils"
require "xdg"

module Tahweel
  # Handles the OAuth 2.0 Authorization flow for the application.
  #
  # This class is responsible for:
  # 1. Determining the secure storage path for the token.
  # 2. Checking if valid credentials already exist.
  # 3. Initiating the OAuth 2.0 flow via a local web server if needed.
  # 4. Exchanging the authorization code for credentials and persisting them.
  class Authorizer
    CLIENT_ID = "296751211179-4cfbr5di1mremlu1kb03m3uog73u1g61.apps.googleusercontent.com"
    CLIENT_SECRET = "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"

    PORT = 3027
    REDIRECT_URI = "http://localhost:#{PORT}/".freeze
    USER_ID = "default"

    # Convenience class method to authorize the user.
    # Instantiates the Authorizer and calls {#authorize}.
    #
    # @return [Google::Auth::UserRefreshCredentials] The authorized credentials.
    def self.authorize = new.authorize

    # Convenience class method to clear stored credentials.
    #
    # @return [void]
    def self.clear_credentials = new.clear_credentials

    # Initializes a new Authorizer instance.
    # Sets up the Google Auth client and token store.
    def initialize
      @client_id = Google::Auth::ClientId.new(CLIENT_ID, CLIENT_SECRET)
      @token_store = Google::Auth::Stores::FileTokenStore.new(file: token_path)
      @authorizer = Google::Auth::UserAuthorizer.new(@client_id, Google::Apis::DriveV3::AUTH_DRIVE, @token_store)
    end

    # Performs the authorization process.
    # Checks for existing valid credentials; if none are found, initiates the OAuth flow.
    #
    # @return [Google::Auth::UserRefreshCredentials] The valid user credentials.
    def authorize
      credentials = @authorizer.get_credentials(USER_ID)
      return credentials if credentials

      perform_oauth_flow
    end

    # Clears the stored credentials file.
    #
    # @return [void]
    def clear_credentials
      path = token_path
      return unless File.exist?(path)

      File.delete(path)
    end

    private

    # Determines the OS-specific path for storing the `token.yaml` file.
    # Prioritizes XDG Base Directory specification, falls back to `~/.cache` if needed.
    #
    # @return [String] The absolute path to the token file.
    def token_path
      xdg = XDG.new
      base_dir = xdg.cache_home.to_s
      base_dir = File.join(Dir.home, ".cache") if base_dir.nil? || base_dir.empty?

      token_dir = File.join(base_dir, "tahweel")
      FileUtils.mkdir_p(token_dir)
      File.join(token_dir, "token.yaml")
    end

    # Orchestrates the interactive OAuth 2.0 flow.
    # Opens the browser, spins up a local TCP server, waits for the callback,
    # and exchanges the code for credentials.
    #
    # @return [Google::Auth::UserRefreshCredentials] The newly obtained credentials.
    # @raise [RuntimeError] If no authorization code is received.
    def perform_oauth_flow
      server = TCPServer.new("localhost", PORT)
      code = nil

      begin
        open_browser_for_auth
        code = listen_for_auth_code(server)
      ensure
        server.close
      end

      raise "Authorization failed: No code received." unless code

      @authorizer.get_and_store_credentials_from_code(user_id: USER_ID, code:, base_url: REDIRECT_URI)
    end

    # Opens the system default browser to the Google Authorization URL.
    def open_browser_for_auth = Launchy.open(@authorizer.get_authorization_url(base_url: REDIRECT_URI))

    # Listens on the local server for the OAuth callback request.
    # Handles multiple incoming requests to filter out noise (like favicon.ico).
    #
    # @param server [TCPServer] The running local TCP server.
    # @return [String, nil] The authorization code if found, otherwise nil.
    def listen_for_auth_code(server)
      loop do
        socket = server.accept
        request_line = socket.gets

        next socket.close unless request_line

        code = handle_request(socket, request_line)
        socket.close

        return code if code
      end
    end

    # Parses the incoming HTTP request line to extract the authorization code.
    # Responds with appropriate HTTP status/content.
    #
    # @param socket [TCPSocket] The client socket.
    # @param request_line [String] The first line of the HTTP request.
    # @return [String, nil] The authorization code if the request matches the callback pattern.
    def handle_request(socket, request_line)
      # Match GET requests containing the 'code' parameter
      # Works for /?code=... or /oauth2callback?code=...
      if request_line =~ /GET .*\?code=(.*) HTTP/
        respond_with_success(socket)
        Regexp.last_match(1).split.first
      else
        respond_with_not_found(socket)
      end
    end

    # Sends a success HTML response to the browser.
    # Reads the content from `lib/tahweel/templates/success.html`.
    #
    # @param socket [TCPSocket] The client socket.
    def respond_with_success(socket)
      html_path = File.expand_path("templates/success.html", __dir__)
      html_content = File.read(html_path)

      socket.print "HTTP/1.1 200 OK\r\n" \
                   "Content-Type: text/html\r\n" \
                   "Content-Length: #{html_content.bytesize}\r\n" \
                   "Connection: close\r\n" \
                   "\r\n" \
                   "#{html_content}"
    end

    # Sends a 404 Not Found response to the browser.
    #
    # @param socket [TCPSocket] The client socket.
    def respond_with_not_found(socket) = socket.print "HTTP/1.1 404 Not Found\r\n\r\n"
  end
end
