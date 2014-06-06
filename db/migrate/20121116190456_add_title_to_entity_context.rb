class AddTitleToEntityContext < ActiveRecord::Migration
  def change
    add_column :entity_contexts, :title, :string
  end
end
