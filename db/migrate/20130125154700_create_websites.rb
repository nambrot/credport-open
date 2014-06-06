class CreateWebsites < ActiveRecord::Migration
  def change
    create_table :websites do |t|
      t.string :url
      t.string :image
      t.string :title
      t.integer :user_id
      t.string :verification_code

      t.timestamps

      
    end
    add_index :websites, :user_id
    add_index :websites, :url, :unique => true
    add_index :websites, :verification_code
  end
end
