$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "houston/slack/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "houston-slack"
  spec.version     = Houston::Slack::VERSION
  spec.authors     = ["Bob Lail"]
  spec.email       = ["bob.lailfamily@gmail.com"]

  spec.summary     = "Integrates Houston with Slack"
  spec.description = "Allows Houston to listen to conversations on Slack and respond"
  spec.homepage    = "https://github.com/houston/houston-slack"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]
  spec.test_files = Dir["test/**/*"]

  # https://blog.jcoglan.com/2013/05/06/websocket-driver-an-io-agnostic-websocket-module-or-why-most-protocol-libraries-arent/
  spec.add_dependency "websocket-driver"
  spec.add_dependency "multi_json"
  spec.add_dependency "faraday"

  spec.add_development_dependency "bundler", "~> 1.10.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "houston-core", ">= 0.5.3"
end
