class CreatePhones < ActiveRecord::Migration
  def change
    create_table :phones do |t|
      t.string :phone
      t.integer :user_id
      t.string :verification_code

      t.timestamps
    end
    add_index :phones, :phone, :unique => true
    add_index :phones, :user_id
    add_index :phones, :verification_code
  end
end
