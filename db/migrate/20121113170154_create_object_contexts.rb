class CreateObjectContexts < ActiveRecord::Migration
  def change
    create_table :entity_contexts do |t|
      t.string :name
      t.text :properties
      t.integer :application_id

      t.timestamps
    end
    add_index :entity_contexts, :name, :unique => true
  end
end