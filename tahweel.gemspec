# frozen_string_literal: true

require_relative "lib/tahweel/version"

Gem::Specification.new do |spec|
  spec.name = "tahweel"
  spec.version = Tahweel::VERSION
  spec.authors = ["Ali Hamdi Ali Fadel"]
  spec.email = ["aliosm1997@gmail.com"]

  spec.summary = "Tahweel is a tool for converting PDF files to text using OCR."
  spec.description = "Tahweel is a tool for converting PDF files to txt, docx, or json using OCR " \
                     "through multiple engines, currently supporting Google Drive only."
  spec.homepage = "https://github.com/ieasybooks/tahweel.rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ieasybooks/tahweel.rb"
  spec.metadata["changelog_uri"] = "https://github.com/ieasybooks/tahweel.rb/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "bin"
  spec.executables = %w[tahweel tahweel-ui tahweel-clear]
  spec.require_paths = ["lib"]

  spec.add_dependency "caracal", "~> 1.4"
  spec.add_dependency "csv", "~> 3.3"
  spec.add_dependency "fiddle", "~> 1.1"
  spec.add_dependency "glimmer-dsl-libui", "~> 0.13.1"
  spec.add_dependency "google-apis-drive_v3", "~> 0.74.0"
  spec.add_dependency "googleauth", "~> 1.16"
  spec.add_dependency "launchy", "~> 3.1"
  spec.add_dependency "openssl", "~> 3.3"
  spec.add_dependency "ruby-vips", "~> 2.2"
  spec.add_dependency "xdg"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
