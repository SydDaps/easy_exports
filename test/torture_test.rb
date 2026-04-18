# frozen_string_literal: true

require 'test_helper'

# Torture tests — unusual-but-possible inputs that exercise the formatter and
# batching pipeline. These lock in subtle behaviors (nil handling, matcher
# ordering, cross-model isolation, etc.) documented nowhere else in the suite.
class TortureTest < ActiveSupport::TestCase
  USER_KEY = 'user_aliases_first_name'

  setup do
    Phone.delete_all
    Email.delete_all
    User.delete_all
    User.reset_exportable_attributes_cache!
    Phone.reset_exportable_attributes_cache!
    Email.reset_exportable_attributes_cache!
  end

  teardown do
    %w[user phone email].each do |klass|
      User.exportable_attribute_formatters_store.delete(klass)
      User.disabled_type_formatters_store.delete(klass) if User.respond_to?(:disabled_type_formatters_store)
      User.disabled_exportable_type_formatters_store&.delete(klass) if User.respond_to?(:disabled_exportable_type_formatters_store)
      User.overridden_type_formatters_store.delete(klass)
    end
    EasyExports.type_formatters = EasyExports::TYPE_FORMATTERS.dup
    EasyExports.csv_header_formatter = EasyExports::DEFAULT_CSV_HEADER_FORMATTER
    User.reset_exportable_attributes_cache!
    Phone.reset_exportable_attributes_cache!
    Email.reset_exportable_attributes_cache!
  end

  # --- Nil / empty value insanity ---

  test 'nil boolean does not get coerced to "No"' do
    # Type matcher is v == true || v == false; nil does NOT match.
    # Also, the resolver short-circuits nil before the type path.
    refute EasyExports::TYPE_MATCHERS[:boolean].call(nil), 'nil must not match :boolean matcher'
  end

  test 'type formatter never sees nil (short-circuit)' do
    raised = false
    User.send(:format_exportable_type, :string, ->(v) { raise 'should not receive nil' if v.nil?; v })
    user = User.create!(first_name: 'a', last_name: 'b')
    user.update_column(:first_name, nil)

    assert_nothing_raised { User.generate_exports({ 'User' => ['First name'] }) }
    raised = true
    assert raised
  end

  test 'custom per-attribute formatter DOES receive nil (asymmetry with type formatter)' do
    seen = []
    User.send(:format_exportable_attribute, :first_name, ->(v) { seen << v; v.to_s })
    user = User.create!(first_name: 'a', last_name: 'b')
    user.update_column(:first_name, nil)

    User.generate_exports({ 'User' => ['First name'] })

    assert_includes seen, nil,
                    'custom formatters must be nil-aware; type formatters do not see nil'
  end

  test 'empty export (zero records) produces header-only CSV' do
    export = User.generate_exports({ 'User' => ['First name'] })

    assert_empty export.data
    assert_equal 1, export.csv_string.lines.size, 'only the header row should be present'
  end

  test 'empty string is not mangled by :string formatter' do
    User.send(:format_exportable_type, :string, ->(v) { v.sub(/^./, &:upcase) })
    User.create!(first_name: '', last_name: 'b')

    export = User.generate_exports({ 'User' => ['First name'] })

    assert_equal [''], export.data.map { |row| row[USER_KEY] }
  end

  # --- Matcher collision torture ---

  test 'string starting with 0 AND containing @ hits leading_zero_string first' do
    Email.create!(address: '0@example.com')

    export = Email.generate_exports({ 'Email' => ['Address'] })

    assert_equal ["'0@example.com"], export.data.map { |row| row['email_address'] },
                 'matcher order: leading_zero_string wins over any later matcher'
  end

  test 'unicode accented first character gets uppercased correctly' do
    User.send(:format_exportable_type, :string, ->(v) { v.sub(/^./, &:upcase) })
    User.create!(first_name: 'émile', last_name: 'z')

    export = User.generate_exports({ 'User' => ['First name'] })

    assert_equal ['Émile'], export.data.map { |row| row[USER_KEY] }
  end

  # --- Batching paranoia ---

  test 'batch_size 1 with non-default order preserves global order across every single-row batch' do
    %w[c a b].each { |n| User.create!(first_name: n, last_name: 'x') }

    export = User.generate_exports({ 'User' => ['First name'] }, [], order: { first_name: :asc }, batch_size: 1)

    # Default :string formatter is NOT set globally; names stay lowercase.
    assert_equal %w[a b c], export.data.map { |row| row[USER_KEY] }
  end

  test 'ordering ties on created_at: output is stable across batches' do
    t = Time.zone.local(2025, 1, 5, 9, 0)
    3.times.map { |i| User.create!(first_name: "u#{i}", last_name: 'x', created_at: t) }

    # Two separate calls with a tiny batch_size — order should match.
    export1 = User.generate_exports({ 'User' => ['First name'] }, [], batch_size: 1)
    export2 = User.generate_exports({ 'User' => ['First name'] }, [], batch_size: 1)

    assert_equal export1.data.map { |r| r[USER_KEY] },
                 export2.data.map { |r| r[USER_KEY] },
                 'repeated calls with ties must be stable; if this fails, add :id as a tie-breaker'
  end

  # --- Cross-model pollution ---

  test 'per-model :string formatters do not leak across models' do
    User.send(:format_exportable_type, :string, ->(v) { "U:#{v}" })
    Email.send(:format_exportable_type, :string, ->(v) { "E:#{v}" })

    User.create!(first_name: 'alice', last_name: 'a')
    Email.create!(address: 'plain-string')  # no @ so it hits :string matcher

    user_export = User.generate_exports({ 'User' => ['First name'] })
    email_export = Email.generate_exports({ 'Email' => ['Address'] })

    assert_equal ['U:alice'],        user_export.data.map { |r| r[USER_KEY] }
    assert_equal ['E:plain-string'], email_export.data.map { |r| r['email_address'] }
  end

  test 'when parent exports an association, the association uses its OWN formatter' do
    User.send(:format_exportable_type, :string, ->(v) { "USER:#{v}" })
    Phone.send(:format_exportable_type, :string, ->(v) { "PHONE:#{v}" })

    user = User.create!(first_name: 'alice', last_name: 'a')
    Phone.create!(number: 'abc', user: user)

    export = User.generate_exports({ 'User' => ['First name'], 'Phones' => ['Number'] })
    row = export.data.first

    assert_equal 'USER:alice', row[USER_KEY],         'self column uses User formatter'
    assert_equal 'PHONE:abc',  row['phones_number'],  'association column uses Phone formatter'
  end

  # --- Pure trolling ---

  test 'a global type formatter that raises propagates the error (not swallowed)' do
    EasyExports.configure { |c| c.type_formatters[:boolean] = ->(_v) { raise 'boom' } }

    # No boolean columns in the dummy app, so no export will actually fire this,
    # but the type_formatters setter itself must not silently swallow junk.
    assert_raises(RuntimeError) do
      EasyExports.type_formatters[:boolean].call(true)
    end
  end

  test 're-declaring format_exportable_attribute: last one wins' do
    User.send(:format_exportable_attribute, :first_name, ->(_v) { 'FIRST' })
    User.send(:format_exportable_attribute, :first_name, ->(_v) { 'SECOND' })
    User.create!(first_name: 'ignored', last_name: 'b')

    export = User.generate_exports({ 'User' => ['First name'] })

    assert_equal ['SECOND'], export.data.map { |row| row[USER_KEY] }
  end

  test 'custom formatter that raises propagates (not swallowed)' do
    User.send(:format_exportable_attribute, :first_name, ->(_v) { raise 'custom boom' })
    User.create!(first_name: 'x', last_name: 'y')

    assert_raises(RuntimeError) do
      User.generate_exports({ 'User' => ['First name'] })
    end
  end
end
