# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "sorbet-rspec"
  spec.version = "0.1.0"
  spec.authors = ["Hongli Lai"]
  spec.email = ["hongli@hongli.nl"]

  spec.summary = "Sorbet integration for RSpec"
  spec.description = "A gem that provides integration between Sorbet type checking and RSpec testing framework"
  spec.homepage = "https://github.com/FooBarWidget/sorbet-rspec"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/FooBarWidget/sorbet-rspec"

  spec.files = Dir["lib/**/*", "rbi/**/*"]

  spec.add_dependency "sorbet-runtime"
  spec.add_dependency "tapioca", ">= 0.16"
  spec.add_dependency "rspec", "~> 3.0"
end
