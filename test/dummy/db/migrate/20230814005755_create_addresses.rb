# frozen_string_literal: true

class CreateAddresses < ActiveRecord::Migration[7.0]
  def change
    create_table :addresses do |t|
      t.string :street_number
      t.belongs_to :user
      t.timestamps
    end
  end
end
