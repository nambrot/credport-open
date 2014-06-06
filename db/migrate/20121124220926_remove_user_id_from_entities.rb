class RemoveUserIdFromEntities < ActiveRecord::Migration
  def change
    remove_columns :entities, :user_id
  end
end
