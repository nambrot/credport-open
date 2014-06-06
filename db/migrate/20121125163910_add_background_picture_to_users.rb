class AddBackgroundPictureToUsers < ActiveRecord::Migration
  def change
    add_column :users, :background_picture, :string
  end
end
