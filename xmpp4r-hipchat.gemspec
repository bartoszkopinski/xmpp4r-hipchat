# coding: utf-8
require File.expand_path('../lib/xmpp4r/hipchat/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'xmpp4r-hipchat'
  spec.version       = XMPP4R::HipChat::VERSION
  spec.authors       = ['Bartosz Kopiński']
  spec.email         = ['bartosz.kopinski@gmail.com']
  spec.description   = 'HipChat client extension to XMPP4R'
  spec.summary       = 'HipChat client extension to XMPP4R'
  spec.homepage      = 'https://github.com/bartoszkopinski/xmpp4r-hipchat'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.add_runtime_dependency 'xmpp4r', ['~> 0.5.6']
  spec.add_development_dependency 'rspec', ['>= 2.13.0']
end
