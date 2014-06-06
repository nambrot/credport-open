class CreateEmails < ActiveRecord::Migration
  def change
    create_table :emails do |t|
      t.string :email
      t.string :md5_hash
      t.string :verification_code
      t.integer :user_id

      t.timestamps
    end
    add_index :emails, :user_id
    add_index :emails, :email, :unique => true
    add_index :emails, :md5_hash
    add_index :emails, :verification_code
  end
end
