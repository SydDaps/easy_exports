# frozen_string_literal: true

require 'test_helper'

class ExportableAttributeFormattersTest < ActiveSupport::TestCase
  setup do
    Phone.delete_all
    User.delete_all
    User.reset_exportable_attributes_cache!
  end

  teardown do
    User.exportable_attribute_formatters_store.delete('user')
    User.reset_exportable_attributes_cache!
  end

  test 'applies a lambda formatter declared on the model' do
    User.send(:format_exportable_attribute, :first_name, ->(v) { v.to_s.upcase })

    User.create!(first_name: 'sydney', last_name: 'S')

    export = User.generate_exports({ 'User' => ['First name'] })

    assert_equal ['SYDNEY'], export.data.map { |row| row['user_aliases_first_name'] }
  end

  test 'accepts a block form' do
    User.send(:format_exportable_attribute, :first_name) { |v| "Name: #{v}" }

    User.create!(first_name: 'stan', last_name: 'A')

    export = User.generate_exports({ 'User' => ['First name'] })

    assert_equal ['Name: stan'], export.data.map { |row| row['user_aliases_first_name'] }
  end

  test 'raises ArgumentError when given no callable' do
    assert_raises(ArgumentError) { User.send(:format_exportable_attribute, :first_name) }
  end

  test 'formatter overrides built-in parse_attribute_value' do
    User.send(:format_exportable_attribute, :created_at, ->(_v) { 'FORMATTED' })

    User.create!(first_name: 'x', last_name: 'y')

    export = User.generate_exports({ 'User' => ['Created at'] })

    assert_equal ['FORMATTED'], export.data.map { |row| row['user_aliases_created_at'] }
  end
end
