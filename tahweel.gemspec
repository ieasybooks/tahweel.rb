# frozen_string_literal: true

require_relative "lib/tahweel/version"

Gem::Specification.new do |spec|
  spec.name = "tahweel"
  spec.version = Tahweel::VERSION
  spec.authors = ["Ali Hamdi Ali Fadel"]
  spec.email = ["aliosm1997@gmail.com"]

  spec.summary = "TODO: Write a short summary, because RubyGems requires one."
  spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "TODO: Put your gem's website or public repo URL here."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
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
  spec.executables = %w[tahweel tahweel-clear]
  spec.require_paths = ["lib"]

  spec.add_dependency "async", "~> 2.34.0"
  spec.add_dependency "caracal", "~> 1.4"
  spec.add_dependency "google-apis-drive_v3", "~> 0.74.0"
  spec.add_dependency "googleauth", "~> 1.16"
  spec.add_dependency "launchy", "~> 3.1"
  spec.add_dependency "ruby-vips", "~> 2.2"
  spec.add_dependency "xdg", "~> 9.5"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
