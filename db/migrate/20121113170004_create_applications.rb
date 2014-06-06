class CreateApplications < ActiveRecord::Migration
  def change
    create_table :applications do |t|
      t.string :name
      t.string :redirect_uri
      t.integer :user_id
      t.timestamps
    end
    add_index :applications, :name, :unique => true
  end
end
