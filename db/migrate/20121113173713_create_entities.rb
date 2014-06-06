class CreateEntities < ActiveRecord::Migration
  def change
    create_table :entities do |t|
      t.string :uid
      t.string :url
      t.string :image
      t.text :credentials
      t.text :properties
      t.integer :user_id
      t.integer :context_id
      t.string :name
      t.timestamps
    end
    add_index :entities, [:uid, :context_id], :unique => true
  end
end
