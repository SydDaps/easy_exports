# frozen_string_literal: true

class UserHasAndBelongsToManyEmails < ActiveRecord::Migration[7.0]
  create_table :emails_users, id: false do |t|
    t.belongs_to :email
    t.belongs_to :user
  end
end
