lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "simple_contracts/version"

Gem::Specification.new do |spec|
  spec.name          = "simple_contracts"
  spec.version       = SimpleContracts::VERSION
  spec.authors       = ["bibendi"]
  spec.email         = ["merkushin.m.s@gmail.com"]

  spec.summary       = "Plain Old Ruby Object Implementation of Contract"
  spec.homepage      = "https://github.com/bibendi/simple_contracts"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob('lib/**/*') + %w(LICENSE.txt README.md)
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "celluloid", "~> 0.17"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "pry-byebug", "~> 3"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "test-unit", "~> 3"
end
