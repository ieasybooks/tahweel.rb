# frozen_string_literal: true

require "spec_helper"
require "tahweel/authorizer"

RSpec.describe Tahweel::Authorizer do
  subject(:authorizer) { described_class.new }

  let(:google_authorizer) { instance_double(Google::Auth::UserAuthorizer) }

  before do
    # The XDG gem defines methods dynamically, so instance_double verification fails.
    xdg = double("XDG", cache_home: "/tmp/cache") # rubocop:disable RSpec/VerifiedDoubles
    allow(XDG).to receive(:new).and_return(xdg)
    allow(FileUtils).to receive(:mkdir_p).and_call_original

    # Stub out the Google user authorizer to avoid real network / token store interactions.
    allow(Google::Auth::UserAuthorizer).to receive(:new).and_return(google_authorizer)
  end

  describe ".authorize" do
    it "instantiates a new authorizer and delegates to #authorize" do # rubocop:disable RSpec/MultipleExpectations,RSpec/ExampleLength
      instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:authorize).and_return(:creds)

      expect(described_class.authorize).to eq(:creds)

      expect(described_class).to have_received(:new)
      expect(instance).to have_received(:authorize)
    end
  end

  describe ".clear_credentials" do
    it "instantiates a new authorizer and delegates to #clear_credentials" do # rubocop:disable RSpec/MultipleExpectations,RSpec/ExampleLength
      instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:clear_credentials)

      described_class.clear_credentials

      expect(described_class).to have_received(:new)
      expect(instance).to have_received(:clear_credentials)
    end
  end

  describe "#authorize" do
    context "when existing credentials are present" do
      it "returns the existing credentials without performing the OAuth flow" do # rubocop:disable RSpec/MultipleExpectations
        allow(google_authorizer).to receive(:get_credentials).with(described_class::USER_ID).and_return(:creds)

        # We spy on the private method simply to ensure it's NOT called, confirming the early return.
        # Note: Spying on the subject under test is partial mocking, but acceptable here for verification.
        allow(authorizer).to receive(:perform_oauth_flow) # rubocop:disable RSpec/SubjectStub

        expect(authorizer.authorize).to eq(:creds)
        expect(authorizer).not_to have_received(:perform_oauth_flow) # rubocop:disable RSpec/SubjectStub
        expect(google_authorizer).to have_received(:get_credentials).with(described_class::USER_ID)
      end
    end

    context "when no existing credentials are present (interactive flow)" do
      let(:server) { instance_double(TCPServer) }

      before do
        allow(google_authorizer).to receive(:get_credentials).with(described_class::USER_ID).and_return(nil)
        allow(TCPServer).to receive(:new).with("localhost", described_class::PORT).and_return(server)
        allow(server).to receive(:close)
        allow(Launchy).to receive(:open)
      end

      context "when on a non-Windows platform" do # rubocop:disable RSpec/NestedGroups
        before { allow(Gem).to receive(:win_platform?).and_return(false) }

        it "opens the browser using Launchy, exchanges the code, and returns credentials" do # rubocop:disable RSpec/MultipleExpectations,RSpec/ExampleLength
          allow(authorizer).to receive(:listen_for_auth_code).and_return("AUTH_CODE") # rubocop:disable RSpec/SubjectStub
          allow(google_authorizer)
            .to receive(:get_and_store_credentials_from_code)
            .with(
              user_id: described_class::USER_ID,
              code: "AUTH_CODE",
              base_url: described_class::REDIRECT_URI
            )
            .and_return(:new_creds)
          allow(google_authorizer).to receive(:get_authorization_url).and_return("http://auth.url")

          result = authorizer.authorize

          expect(result).to eq(:new_creds)
          expect(Launchy).to have_received(:open).with("http://auth.url")
          expect(server).to have_received(:close)
        end
      end

      context "when on a Windows platform" do # rubocop:disable RSpec/NestedGroups
        before do
          allow(Gem).to receive(:win_platform?).and_return(true)
          allow(authorizer).to receive(:system) # rubocop:disable RSpec/SubjectStub
        end

        it "opens the browser using the 'start' command, exchanges the code, and returns credentials" do # rubocop:disable RSpec/MultipleExpectations,RSpec/ExampleLength
          allow(authorizer).to receive(:listen_for_auth_code).and_return("AUTH_CODE") # rubocop:disable RSpec/SubjectStub
          allow(google_authorizer)
            .to receive(:get_and_store_credentials_from_code)
            .with(
              user_id: described_class::USER_ID,
              code: "AUTH_CODE",
              base_url: described_class::REDIRECT_URI
            )
            .and_return(:new_creds)
          allow(google_authorizer).to receive(:get_authorization_url).and_return("http://auth.url")

          result = authorizer.authorize

          expect(result).to eq(:new_creds)
          expect(authorizer).to have_received(:system).with("start \"\" \"http://auth.url\"") # rubocop:disable RSpec/SubjectStub
          expect(Launchy).not_to have_received(:open)
          expect(server).to have_received(:close)
        end
      end

      it "raises an error if no code is received" do # rubocop:disable RSpec/MultipleExpectations,RSpec/ExampleLength
        allow(authorizer).to receive(:listen_for_auth_code).and_return(nil) # rubocop:disable RSpec/SubjectStub
        allow(google_authorizer).to receive(:get_and_store_credentials_from_code)
        allow(google_authorizer).to receive(:get_authorization_url).and_return("http://auth.url")

        expect { authorizer.authorize }.to raise_error(RuntimeError, "Authorization failed: No code received.")

        expect(server).to have_received(:close)
        expect(google_authorizer).not_to have_received(:get_and_store_credentials_from_code)
      end
    end
  end

  describe "#clear_credentials" do
    let(:token_path) { "/tmp/cache/tahweel/token.yaml" }

    before do
      # Mock FileTokenStore to avoid real file system errors during initialization
      allow(Google::Auth::Stores::FileTokenStore).to receive(:new).and_return(:file_token_store)

      allow(File).to receive(:exist?).with(token_path).and_return(true)
      allow(File).to receive(:delete).with(token_path)
      allow(authorizer).to receive(:token_path).and_return(token_path) # rubocop:disable RSpec/SubjectStub
    end

    it "deletes the credentials file if it exists" do
      authorizer.clear_credentials
      expect(File).to have_received(:delete).with(token_path)
    end

    it "does nothing if the credentials file does not exist" do
      allow(File).to receive(:exist?).with(token_path).and_return(false)
      authorizer.clear_credentials
      expect(File).not_to have_received(:delete)
    end
  end

  describe "incoming request handling logic" do
    let(:server) { instance_double(TCPServer) }
    let(:valid_socket) { instance_double(TCPSocket, close: nil) }
    let(:invalid_socket) { instance_double(TCPSocket, close: nil) }
    let(:empty_socket) { instance_double(TCPSocket, close: nil) }

    before do
      allow(google_authorizer).to receive(:get_credentials).with(described_class::USER_ID).and_return(nil)
      allow(google_authorizer).to receive_messages(
        get_authorization_url: "http://auth.url",
        get_and_store_credentials_from_code: :creds
      )

      allow(Launchy).to receive(:open)

      allow(TCPServer).to receive(:new).with("localhost", described_class::PORT).and_return(server)
      allow(server).to receive(:close)
    end

    it "processes a valid request sequence (ignores noise -> processes code)" do # rubocop:disable RSpec/MultipleExpectations,RSpec/ExampleLength
      allow(server).to receive(:accept).and_return(invalid_socket, valid_socket)

      # Noise request (favicon)
      allow(invalid_socket).to receive(:gets).and_return("GET /favicon.ico HTTP/1.1")
      allow(invalid_socket).to receive(:print)

      # Valid request
      allow(valid_socket).to receive(:gets).and_return("GET /?code=secret_code HTTP/1.1")
      allow(valid_socket).to receive(:print)

      result = authorizer.authorize

      expect(result).to eq(:creds)
      expect(invalid_socket).to have_received(:print).with("HTTP/1.1 404 Not Found\r\n\r\n")
      expect(invalid_socket).to have_received(:close)

      # Verify success response
      template_path = File.expand_path("../../lib/tahweel/templates/success.html", __dir__)
      template_body = File.read(template_path)
      expected_response = "HTTP/1.1 200 OK\r\n" \
                          "Content-Type: text/html\r\n" \
                          "Content-Length: #{template_body.bytesize}\r\n" \
                          "Connection: close\r\n" \
                          "\r\n" \
                          "#{template_body}"
      expect(valid_socket).to have_received(:print).with(expected_response)
      expect(valid_socket).to have_received(:close)

      expect(google_authorizer).to have_received(:get_and_store_credentials_from_code).with(
        hash_including(code: "secret_code")
      )
    end

    it "handles empty requests (closed connections) gracefully" do # rubocop:disable RSpec/MultipleExpectations,RSpec/ExampleLength
      allow(server).to receive(:accept).and_return(empty_socket, valid_socket)

      # Empty request (gets returns nil)
      allow(empty_socket).to receive(:gets).and_return(nil)

      # Valid request to ensure loop finishes
      allow(valid_socket).to receive(:gets).and_return("GET /?code=secret_code HTTP/1.1")
      allow(valid_socket).to receive(:print)

      authorizer.authorize

      expect(empty_socket).to have_received(:close)
      expect(valid_socket).to have_received(:close)
    end
  end

  describe "token storage path" do
    it "uses the XDG cache directory for token storage" do # rubocop:disable RSpec/MultipleExpectations
      allow(Google::Auth::Stores::FileTokenStore).to receive(:new).and_call_original

      described_class.new

      expect(FileUtils).to have_received(:mkdir_p).with("/tmp/cache/tahweel").at_least(:once)
      expect(Google::Auth::Stores::FileTokenStore).to have_received(:new).with(file: "/tmp/cache/tahweel/token.yaml")
    end

    it "uses the home directory for token storage if the XDG cache directory is not set" do # rubocop:disable RSpec/MultipleExpectations,RSpec/ExampleLength
      allow(Google::Auth::Stores::FileTokenStore).to receive(:new).and_call_original
      allow(XDG).to receive(:new).and_return(double("XDG", cache_home: nil)) # rubocop:disable RSpec/VerifiedDoubles
      allow(FileUtils).to receive(:mkdir_p).and_call_original

      described_class.new

      expect(FileUtils).to have_received(:mkdir_p).with(File.join(Dir.home, ".cache/tahweel")).at_least(:once)
      expect(Google::Auth::Stores::FileTokenStore).to have_received(:new).with(
        file: File.join(Dir.home, ".cache/tahweel/token.yaml")
      )
    end
  end
end
