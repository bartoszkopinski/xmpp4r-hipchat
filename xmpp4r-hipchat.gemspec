# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xmpp4r/hipchat/version'

Gem::Specification.new do |spec|
  spec.name          = 'xmpp4r-hipchat'
  spec.version       = Jabber::MUC::Hipchat::VERSION
  spec.authors       = ['Bartosz Kopiński']
  spec.email         = ['bartosz.kopinski@gmail.com']
  spec.description   = 'HipChat client extension to xmpp4r'
  spec.summary       = 'HipChat client extension to xmpp4r'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.add_runtime_dependency 'xmpp4r', ['~> 0.5']
  spec.add_development_dependency 'bundler', '~> 1.4'
  spec.add_development_dependency 'rake'
end
