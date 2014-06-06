class CreateConnectionContexts < ActiveRecord::Migration
  def change
    create_table :connection_contexts do |t|
      t.string :name
      t.boolean :async
      t.string :cardinality
      t.string :connection_type
      t.text :properties
      t.integer :application_id

      t.timestamps
    end
    add_index :connection_contexts, :name, :uniqueness => true
  end
end
