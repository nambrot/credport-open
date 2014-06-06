class CreateProfilePictures < ActiveRecord::Migration
  def change
    create_table :profile_pictures do |t|
      t.string :url
      t.integer :user_id

      t.timestamps
    end
    add_index :profile_pictures, :user_id
    add_index :profile_pictures, [:url, :user_id], :unique => true
  end
end
