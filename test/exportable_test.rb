# frozen_string_literal: true

require 'test_helper'

class ExportableTest < ActiveSupport::TestCase
  test 'it should generate exportable fields with main User association and all of its attributes' do
    assert User.exportable_fields.keys.include? 'User'
    assert_equal(
      User.exportable_fields['User'],
      User.attribute_names.map { |attribute| attribute.humanize(keep_id_suffix: true).downcase }
    )
  end
end
