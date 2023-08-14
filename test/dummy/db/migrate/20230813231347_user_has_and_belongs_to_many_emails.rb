# frozen_string_literal: true

class UserHasAndBelongsToManyEmails < ActiveRecord::Migration[7.0]
  create_table :users_emails, id: false do |t|
    t.belongs_to :user
    t.belongs_to :email
  end
end
