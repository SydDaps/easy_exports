# frozen_string_literal: true

class CreateEmails < ActiveRecord::Migration[7.0]
  def change
    create_table :emails do |t|
      t.string :address
      t.timestamps
    end
  end
end
