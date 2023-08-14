# frozen_string_literal: true

require 'test_helper'

class ExportableAttributesTest < ActiveSupport::TestCase
  test 'it should generate exportable attributes for model and all of its attributes' do
    assert_equal(
      User.exportable_attributes['User'],
      User.attribute_names.map { |attribute| attribute.humanize(keep_id_suffix: true).downcase }
    )
  end

  test 'it should generate exportable attributes for all associations defined in model class with all of their attributes' do
    assert User.exportable_attributes.keys.include? 'Phones'
    assert User.exportable_attributes.keys.include? 'Emails'

    assert_equal(
      User.exportable_attributes['Phones'],
      Phone.attribute_names.map { |attribute| attribute.humanize(keep_id_suffix: true).downcase }
    )

    assert_equal(
      User.exportable_attributes['Emails'],
      Email.attribute_names.map { |attribute| attribute.humanize(keep_id_suffix: true).downcase }
    )
  end

  test 'it should exclude attributes passed to exclude_exportable_attributes method from exportable_attributes' do
    # method call in Email class exclude_exportable_attributes all: [:created_at], users: [:first_name]
    email_exportable_attributes = Email.exportable_attributes

    assert_not email_exportable_attributes['Email'].include? 'created at'

    assert_not (email_exportable_attributes['Users'] & ['created at', 'first name']).any?
  end

  test 'it should exclude associations passed to exclude_exportable_associations from exportable_attributes' do
    # method call in Phone class exportable_attributes [:users]
    phone_exportable_attributes = Phone.exportable_attributes

    assert phone_exportable_attributes['User'].blank?
  end

  test 'it should rename exportable_attributes associations to passed association aliases' do
    # method call in User class exportable_association_aliases emails: :user_emails_alias
    address_exportable_attributes = Address.exportable_attributes

    assert address_exportable_attributes['User alias'].present?
  end

  test 'it raise argument error for invalid association passed for association_aliases' do
    assert_raises ArgumentError do
      Post.exportable_attributes
    end
  end
end
