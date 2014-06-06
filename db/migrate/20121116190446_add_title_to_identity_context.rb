class AddTitleToIdentityContext < ActiveRecord::Migration
  def change
    add_column :identity_contexts, :title, :string
  end
end
