class AddNameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :name, :string, :default => "Anonymous User"
  end
end
