# frozen_string_literal: true

require_relative "lib/bridgetown-media-transformation/version"

Gem::Specification.new do |spec|
  spec.name          = "bridgetown-media-transformation"
  spec.version       = BridgetownMediaTransformation::VERSION
  spec.author        = "Julian Rubisch"
  spec.email         = "julian@julianrubisch.at"
  spec.summary       = "Image and video transformation via image_processing and ffmpeg"
  spec.homepage      = "https://github.com/julianrubisch/bridgetown-media-transformation"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r!^(test|script|spec|features|frontend)/!) }
  spec.test_files    = spec.files.grep(%r!^spec/!)
  spec.require_paths = ["lib"]
  spec.metadata      = { "yarn-add" => "bridgetown-media-transformation@#{BridgetownMediaTransformation::VERSION}" }

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "bridgetown", ">= 0.15", "< 2.0"
  spec.add_dependency "image_processing", "~> 1.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "nokogiri", "~> 1.6"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-bridgetown", "~> 0.2"
end
