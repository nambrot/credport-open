class AddEntityIdToApplications < ActiveRecord::Migration
  def change
    add_column :applications, :entity_id, :integer
  end
end
