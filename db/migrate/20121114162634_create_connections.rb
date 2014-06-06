class CreateConnections < ActiveRecord::Migration
  def change
    create_table :connections do |t|
      t.integer :from_id
      t.string :from_type
      t.integer :to_id
      t.string :to_type
      t.integer :context_id
      t.text :properties

      t.timestamps
    end
    
    add_index :connections, [:to_type, :to_id]
    add_index :connections, [:from_type, :from_id]
    add_index :connections, :context_id
  end
end
