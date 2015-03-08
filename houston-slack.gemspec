$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "houston/slack/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "houston-slack"
  s.version     = Houston::Slack::VERSION
  s.authors     = ["Bob Lail"]
  s.email       = ["bob.lailfamily@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "Integrates Houston with Slack"
  s.description = "Allows Houston to listen to conversations on Slack and respond"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"

  # https://blog.jcoglan.com/2013/05/06/websocket-driver-an-io-agnostic-websocket-module-or-why-most-protocol-libraries-arent/
  s.add_dependency "websocket-driver"
  s.add_dependency "multi_json"
end
