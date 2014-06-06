class CreateRecommendations < ActiveRecord::Migration
  def change
    create_table :recommendations do |t|
      t.string :role
      t.text :text
      t.integer :connection_in_db_id
      t.integer :recommender_id
      t.integer :recommended_id

      t.timestamps
    end
    add_index :recommendations, :connection_in_db_id, :unique => true
    add_index :recommendations, [:recommender_id, :recommended_id], :unique => true
  end
end
