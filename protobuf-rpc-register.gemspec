# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'protobuf/rpc/register/version'

Gem::Specification.new do |spec|
  spec.name          = "protobuf-rpc-register"
  spec.version       = Protobuf::Rpc::Register::VERSION
  spec.authors       = ["scorix"]
  spec.email         = ["scorix@gmail.com"]

  spec.summary       = %q{Register for rpc services using protobuf rpc.}
  spec.description   = %q{Register for rpc services using protobuf rpc.}
  spec.homepage      = "https://github.com/scorix/protobuf-rpc-register"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-its', '~> 1.2'
  spec.add_development_dependency 'pry', "~> 0.10"
  spec.add_development_dependency 'simplecov', '> 0.11'
  spec.add_development_dependency 'msgpack', "~> 0.5"
  spec.add_development_dependency 'multi_json', "~> 1.0"
  spec.add_development_dependency 'oj', "~> 2.0"

  spec.add_runtime_dependency 'protobuf', '~> 3.5'
  spec.add_runtime_dependency 'active_interaction', '~> 3.0'
end
