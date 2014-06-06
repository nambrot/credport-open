class AddTaglineToUsers < ActiveRecord::Migration
  def change
    add_column :users, :tagline, :text, :default => ''
  end
end
