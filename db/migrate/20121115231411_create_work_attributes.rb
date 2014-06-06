class CreateWorkAttributes < ActiveRecord::Migration
  def change
    create_table :work_attributes do |t|
      t.string :title
      t.text :summary
      t.text :to
      t.text :from
      t.boolean :current
      t.integer :workplace_id
      t.integer :user_id
      t.integer :added_by
      t.boolean :visible, :default => true
      t.timestamps
    end
    add_index :work_attributes, :user_id
    add_index :work_attributes, [:user_id, :workplace_id, :title]
  end
end
