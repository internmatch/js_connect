$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "js_connect/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "js_connect"
  s.version     = JsConnect::VERSION
  s.authors     = ["Ryan Garver"]
  s.email       = ["ryan@internmatch.com"]
  s.homepage    = "https://github.com/internmatch/js_connect"
  s.summary     = "Implements the JSConnect JSONP API for VanillaForums"
  s.description = "Implements the JSConnect JSONP API for VanillaForums"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", ">= 3.1", "< 5"

  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "sqlite3"
end
