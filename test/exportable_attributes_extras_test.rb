# frozen_string_literal: true

require 'test_helper'

class ExportableAttributesExtrasTest < ActiveSupport::TestCase
  def setup
    User.reset_exportable_attributes_cache!
  end

  def teardown
    User.reset_exportable_attributes_cache!
    EasyExports.sensitive_attributes = EasyExports::DEFAULT_SENSITIVE_ATTRIBUTES.dup
    EasyExports.batch_size = EasyExports::DEFAULT_BATCH_SIZE
  end

  test 'memoizes exportable_attributes across calls' do
    first = User.exportable_attributes
    second = User.exportable_attributes

    assert_same first, second
  end

  test 'reset_exportable_attributes_cache! clears the memo' do
    first = User.exportable_attributes
    User.reset_exportable_attributes_cache!
    second = User.exportable_attributes

    assert_equal first, second
    refute_same first, second
  end

  test 'batch_size is configurable globally via EasyExports.configure' do
    EasyExports.configure { |c| c.batch_size = 42 }

    assert_equal 42, EasyExports.batch_size
  end

  test 'excludes configured sensitive attributes by default' do
    EasyExports.sensitive_attributes = ['first_name']

    attrs = User.exportable_attributes['User alias'] || User.exportable_attributes['User aliases'] || User.exportable_attributes.values.first

    refute_includes attrs, 'first name'
  end

  test 'include_sensitive_exportable_attributes opts the model back in' do
    EasyExports.sensitive_attributes = ['first_name']
    User.include_sensitive_exportable_attributes = true
    User.reset_exportable_attributes_cache!

    attrs = User.exportable_attributes.values.first

    assert_includes attrs, 'first name'
  ensure
    User.include_sensitive_exportable_attributes = false
  end
end
