# frozen_string_literal: true

require_relative "tahweel/version"
require_relative "tahweel/authorizer"
require_relative "tahweel/pdf_splitter"
require_relative "tahweel/ocr"

module Tahweel
  class Error < StandardError; end
end
