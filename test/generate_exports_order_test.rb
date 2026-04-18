# frozen_string_literal: true

require 'test_helper'

class GenerateExportsOrderTest < ActiveSupport::TestCase
  setup do
    Phone.delete_all
    Email.delete_all
    User.delete_all

    @older = User.create!(first_name: 'Alice', last_name: 'A', created_at: 3.days.ago)
    @middle = User.create!(first_name: 'Bob',   last_name: 'B', created_at: 2.days.ago)
    @newer = User.create!(first_name: 'Carol', last_name: 'C', created_at: 1.day.ago)
  end

  FIRST_NAME_HEADER = 'user_aliases_first_name' # User has self-alias `user: :user_aliases`

  test 'defaults to created_at DESC when order option is not passed and column exists' do
    export = User.generate_exports({ 'User' => ['First name'] })

    first_names = export.data.map { |row| row[FIRST_NAME_HEADER] }

    assert_equal [@newer.first_name, @middle.first_name, @older.first_name], first_names
  end

  test 'applies an explicit order option (hash)' do
    export = User.generate_exports({ 'User' => ['First name'] }, [], order: { first_name: :asc })

    first_names = export.data.map { |row| row[FIRST_NAME_HEADER] }

    assert_equal [@older.first_name, @middle.first_name, @newer.first_name], first_names
  end

  test 'applies an explicit order option (string)' do
    export = User.generate_exports({ 'User' => ['First name'] }, [], order: 'first_name DESC')

    first_names = export.data.map { |row| row[FIRST_NAME_HEADER] }

    assert_equal [@newer.first_name, @middle.first_name, @older.first_name], first_names
  end

  test 'respects ids filter and still applies default created_at ordering' do
    export = User.generate_exports({ 'User' => ['First name'] }, [@older.id, @newer.id])

    first_names = export.data.map { |row| row[FIRST_NAME_HEADER] }

    assert_equal [@newer.first_name, @older.first_name], first_names
  end

  test 'preserves ordering across batches when row count exceeds batch size' do
    export = User.generate_exports({ 'User' => ['First name'] }, [], order: { first_name: :asc }, batch_size: 2)

    first_names = export.data.map { |row| row[FIRST_NAME_HEADER] }

    assert_equal [@older.first_name, @middle.first_name, @newer.first_name], first_names
  end
end
