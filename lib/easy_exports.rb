# frozen_string_literal: true

require 'active_support/core_ext/module/attribute_accessors'

require 'easy_exports/version'
require 'easy_exports/railtie'
require 'easy_exports/exportable_attribute_resolvers'
require 'easy_exports/exclude_associations_configurations'
require 'easy_exports/exclude_exportable_attributes_configurations'
require 'easy_exports/exportable_association_aliases_configurations'
require 'easy_exports/exportable_attribute_formatters_configurations'
require 'easy_exports/export'
require 'easy_exports/data_loader'
require 'easy_exports/data_attributes_resolver'
require 'easy_exports/exports_generable'
require 'easy_exports/exportable_attributes'

module EasyExports
  DEFAULT_BATCH_SIZE = 1_000
  DEFAULT_SENSITIVE_ATTRIBUTES = %w[
    password_digest
    encrypted_password
    remember_token
    reset_password_token
    confirmation_token
    session_token
    api_key
    secret_token
  ].freeze

  TYPE_MATCHERS = {
    boolean: ->(v) { v == true || v == false },
    datetime: ->(v) { v.is_a?(Date) || v.is_a?(Time) || v.is_a?(DateTime) || v.is_a?(ActiveSupport::TimeWithZone) },
    leading_zero_string: ->(v) { v.is_a?(String) && v.start_with?('0') },
    string: ->(v) { v.is_a?(String) && !v.include?('@') }
  }.freeze

  TYPE_FORMATTERS = {
    boolean: ->(v) { v ? 'Yes' : 'No' },
    datetime: ->(v) { v.strftime('%A, %B %-d, %Y %H:%M') },
    leading_zero_string: ->(v) { "'#{v}" }
  }.freeze

  DEFAULT_CSV_HEADER_FORMATTER = ->(key) { key.to_s.humanize.titleize }

  mattr_accessor :batch_size, default: DEFAULT_BATCH_SIZE
  mattr_accessor :sensitive_attributes, default: DEFAULT_SENSITIVE_ATTRIBUTES.dup
  mattr_accessor :type_formatters, default: TYPE_FORMATTERS.dup
  mattr_accessor :csv_header_formatter, default: DEFAULT_CSV_HEADER_FORMATTER

  def self.configure
    yield self
  end
end
