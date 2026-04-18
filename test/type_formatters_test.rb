# frozen_string_literal: true

require 'test_helper'

class TypeFormattersTest < ActiveSupport::TestCase
  SELF_HEADER_PREFIX = 'user_aliases'

  setup do
    Phone.delete_all
    User.delete_all
    User.reset_exportable_attributes_cache!
  end

  teardown do
    User.exportable_attribute_formatters_store.delete('user')
    User.disabled_type_formatters_store.delete('user')
    User.overridden_type_formatters_store.delete('user')
    EasyExports.type_formatters = EasyExports::TYPE_FORMATTERS.dup
    EasyExports.csv_header_formatter = EasyExports::DEFAULT_CSV_HEADER_FORMATTER
    User.reset_exportable_attributes_cache!
  end

  test 'datetime values use the global default format' do
    User.create!(first_name: 'a', last_name: 'b', created_at: Time.zone.local(2025, 1, 5, 9, 17))

    export = User.generate_exports({ 'User' => ['Created at'] })

    assert_equal ['Sunday, January 5, 2025 09:17'],
                 export.data.map { |row| row["#{SELF_HEADER_PREFIX}_created_at"] }
  end

  test 'CSV headers are titleized by default' do
    User.create!(first_name: 'a', last_name: 'b')

    export = User.generate_exports({ 'User' => ['First name'] })

    assert_match(/User Aliases First Name/, export.csv_string.lines.first)
  end

  test 'hash keys remain snake_case for programmatic consumers' do
    User.create!(first_name: 'a', last_name: 'b')

    export = User.generate_exports({ 'User' => ['First name'] })

    assert_includes export.data.first.keys, "#{SELF_HEADER_PREFIX}_first_name"
  end

  test 'disable_exportable_type_formatter :datetime turns off datetime default for that model' do
    User.send(:disable_exportable_type_formatter, :datetime)
    User.create!(first_name: 'a', last_name: 'b', created_at: Time.zone.local(2025, 1, 5, 9, 17))

    export = User.generate_exports({ 'User' => ['Created at'] })

    assert_kind_of ActiveSupport::TimeWithZone,
                   export.data.first["#{SELF_HEADER_PREFIX}_created_at"]
  end

  test 'per-attribute formatter beats type formatter' do
    User.send(:format_exportable_attribute, :created_at, ->(_v) { 'OVERRIDDEN' })
    User.create!(first_name: 'a', last_name: 'b', created_at: Time.zone.local(2025, 1, 5))

    export = User.generate_exports({ 'User' => ['Created at'] })

    assert_equal ['OVERRIDDEN'], export.data.map { |row| row["#{SELF_HEADER_PREFIX}_created_at"] }
  end

  test 'disable_exportable_type_formatter rejects unknown types' do
    assert_raises(ArgumentError) { User.send(:disable_exportable_type_formatter, :nonexistent) }
  end

  test 'global type_formatter can be overridden via EasyExports.configure' do
    EasyExports.configure { |c| c.type_formatters[:datetime] = ->(v) { v.strftime('%d/%m/%Y') } }
    User.create!(first_name: 'a', last_name: 'b', created_at: Time.zone.local(2025, 1, 5))

    export = User.generate_exports({ 'User' => ['Created at'] })

    assert_equal ['05/01/2025'], export.data.map { |row| row["#{SELF_HEADER_PREFIX}_created_at"] }
  end

  test 'global type_formatter can be disabled by setting to nil' do
    EasyExports.configure { |c| c.type_formatters[:datetime] = nil }
    User.create!(first_name: 'a', last_name: 'b', created_at: Time.zone.local(2025, 1, 5))

    export = User.generate_exports({ 'User' => ['Created at'] })

    assert_kind_of ActiveSupport::TimeWithZone,
                   export.data.first["#{SELF_HEADER_PREFIX}_created_at"]
  end

  test 'csv_header_formatter can be disabled by setting to nil' do
    EasyExports.configure { |c| c.csv_header_formatter = nil }
    User.create!(first_name: 'a', last_name: 'b')

    export = User.generate_exports({ 'User' => ['First name'] })

    assert_match(/user_aliases_first_name/, export.csv_string.lines.first)
  end

  test 'leading-zero strings get the quote prefix by default' do
    user = User.create!(first_name: 'a', last_name: 'b')
    Phone.create!(number: '0244867596', user: user)

    export = Phone.generate_exports({ 'Phone' => ['Number'] })

    assert_equal ["'0244867596"], export.data.map { |row| row['phone_number'] }
  end

  test 'format_exportable_type replaces the default for that model only' do
    User.send(:format_exportable_type, :datetime, ->(v) { v.strftime('%d/%m/%Y') })
    User.create!(first_name: 'a', last_name: 'b', created_at: Time.zone.local(2025, 1, 5, 9, 17))

    export = User.generate_exports({ 'User' => ['Created at'] })

    assert_equal ['05/01/2025'], export.data.map { |row| row["#{SELF_HEADER_PREFIX}_created_at"] }
  end

  test 'format_exportable_type rejects unknown types' do
    assert_raises(ArgumentError) do
      User.send(:format_exportable_type, :nonexistent, ->(v) { v })
    end
  end

  test 'format_exportable_type requires a callable' do
    assert_raises(ArgumentError) do
      User.send(:format_exportable_type, :datetime)
    end
  end

  test 'per-attribute formatter still beats an format_exportable_type' do
    User.send(:format_exportable_type, :datetime, ->(v) { v.strftime('%d/%m/%Y') })
    User.send(:format_exportable_attribute, :created_at, ->(_v) { 'WINS' })
    User.create!(first_name: 'a', last_name: 'b', created_at: Time.zone.local(2025, 1, 5))

    export = User.generate_exports({ 'User' => ['Created at'] })

    assert_equal ['WINS'], export.data.map { |row| row["#{SELF_HEADER_PREFIX}_created_at"] }
  end

  test 'disable_exportable_type_formatter still beats an format_exportable_type' do
    User.send(:format_exportable_type, :datetime, ->(v) { v.strftime('%d/%m/%Y') })
    User.send(:disable_exportable_type_formatter, :datetime)
    User.create!(first_name: 'a', last_name: 'b', created_at: Time.zone.local(2025, 1, 5))

    export = User.generate_exports({ 'User' => ['Created at'] })

    assert_kind_of ActiveSupport::TimeWithZone,
                   export.data.first["#{SELF_HEADER_PREFIX}_created_at"]
  end

  test 'format_exportable_type :string lets models format plain strings, emails are skipped' do
    User.send(:format_exportable_type, :string, ->(v) { v.sub(/^./, &:upcase) })
    User.create!(first_name: 'sydney', last_name: 'dapilah')

    export = User.generate_exports({ 'User' => ['First name'] })

    assert_equal ['Sydney'], export.data.map { |row| row["#{SELF_HEADER_PREFIX}_first_name"] }
  end

  test 'nil values pass through untouched' do
    user = User.create!(first_name: 'a', last_name: 'b')
    user.update_column(:first_name, nil)

    export = User.generate_exports({ 'User' => ['First name'] })

    assert_nil export.data.first["#{SELF_HEADER_PREFIX}_first_name"]
  end
end
