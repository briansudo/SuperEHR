#Loads the lib folder into the root of the gem 
lib = File.expand_path('../lib', __File__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# #Require this version of super_ehr
# require 'super_ehr/version'


Gem::Specification.new do |s|
  s.name        = 'super_ehr'
  s.version     = '1.0.8'
  s.date        = '2015-05-11'
  s.summary     = "Integrate with various EHR APIs seamlessly."
  s.description = "This project generalizes EHR integrations with various EHR vendors. Currently supports Allscripts, Athena, and DrChrono."
  s.authors     = ["Brian Su"]
  s.email       = 'brian@bsu.me'
  s.files       = ["lib/super_ehr.rb"]
  s.homepage    =
    'http://rubygems.org/gems/super_ehr'
  s.license       = 'MIT'


  #Add dependencies for testing with RSpec
  s.add_development_dependency "rspec"

end
