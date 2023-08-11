# frozen_string_literal: true

require_relative 'lib/easy_exports/version'

Gem::Specification.new do |spec|
  spec.name        = 'easy_exports'
  spec.version     = EasyExports::VERSION
  spec.required_ruby_version = '>= 2.7.0'
  spec.authors     = ['Dapilah Sydney']
  spec.email       = ['51008616+SydDaps@users.noreply.github.com']
  spec.homepage    = 'https://github.com/SydDaps/easy_exports'
  spec.summary     = 'Streamline data retrieval in Ruby models'

  spec.description = 'Simplify the way you fetch model data, making coding smoother and data exporting handling a breeze'
  spec.license     = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata['allowed_push_host'] = "'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/SydDaps/easy_exports'
  spec.metadata['changelog_uri'] = 'http://mygemserver.com'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'rails', '>= 7.0.5'
end
