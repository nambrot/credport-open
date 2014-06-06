class CreateIdentities < ActiveRecord::Migration
  def change
    create_table :identities do |t|
      t.string :uid
      t.string :url
      t.string :image
      t.string :name
      t.string :subtitle
      t.text :credentials
      t.text :properties
      t.integer :user_id
      t.integer :context_id
      t.timestamps
    end
    add_index :identities, [:uid, :context_id], :unique => true
  end
end
