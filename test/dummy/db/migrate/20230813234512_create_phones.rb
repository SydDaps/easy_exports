class CreatePhones < ActiveRecord::Migration[7.0]
  def change
    create_table :phones do |t|
      t.string :number
      t.belongs_to :user
      t.timestamps
    end
  end
end
