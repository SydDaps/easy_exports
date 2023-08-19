# frozen_string_literal: true

require_relative 'lib/easy_exports/version'

Gem::Specification.new do |spec|
  spec.name        = 'easy_exports'
  spec.version     = EasyExports::VERSION
  spec.required_ruby_version = '>= 2.7.0'
  spec.authors     = ['Dapilah Sydney']
  spec.email       = ['dapilah.sydney@gmail.com']
  spec.homepage    = 'https://github.com/SydDaps/easy_exports'
  spec.summary     = 'Streamline data retrieval from Rails models'

  spec.description = 'Simplify the way you fetch model data, making coding smoother and data exporting handling a breeze'
  spec.license     = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata['allowed_push_host'] = "https://rubygems.org/"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/SydDaps/easy_exports'
  spec.metadata['changelog_uri'] = "https://rubygems.org/"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_runtime_dependency 'rails', '>= 6.0'
  spec.add_runtime_dependency 'csv', '>= 3.0'

  spec.add_development_dependency 'faker', '~> 3.2'
  spec.add_development_dependency 'rubocop', '~> 1.56'
  spec.add_development_dependency 'rubocop-rails', '~> 2.20'
  spec.add_development_dependency 'byebug', '~> 11.1'
end
