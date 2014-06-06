class CreateIdentityContexts < ActiveRecord::Migration
  def change
    create_table :identity_contexts do |t|
      t.string :name
      t.text :properties
      t.integer :application_id

      t.timestamps
    end
    add_index :identity_contexts, :name, :unique => true
  end
end
