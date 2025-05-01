# cielagonote.gemspec

Gem::Specification.new do |spec|
  spec.name          = "cielagonote"
  spec.version       = "0.4"
  spec.authors       = ["Mike Hall"]
  spec.email         = ["mike@puddingtime.orgy"]

  spec.summary       = "Fast access to a directory of notes."
  spec.description   = "A fast plaintext-first note finder and creator."
  spec.homepage      = "https://github.com/pdxmph/cielagonote"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb"] + Dir["bin/*"] + ["README.md", "LICENSE.txt"]
  spec.executables   = ["cn"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.0"
end
