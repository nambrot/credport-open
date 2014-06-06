class CreateEducationAttributes < ActiveRecord::Migration
  def change
    create_table :education_attributes do |t|
      t.string :classyear
      t.string :station
      t.text :majors
      t.integer :school_id
      t.integer :user_id
      t.boolean :visible, :default => true
      t.integer :added_by
      t.timestamps
    end
    add_index :education_attributes, :user_id
    add_index :education_attributes, [:station, :school_id, :user_id]
  end
end
