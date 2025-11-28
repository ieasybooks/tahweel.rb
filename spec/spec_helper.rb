# frozen_string_literal: true

require "simplecov"

SimpleCov.enable_coverage :branch
SimpleCov.minimum_coverage line: 100, branch: 99
SimpleCov.minimum_coverage_by_file line: 100
SimpleCov.refuse_coverage_drop :line

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/bin/"
end

require "tahweel"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
