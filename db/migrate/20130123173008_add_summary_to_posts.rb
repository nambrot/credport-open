class AddSummaryToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :summary, :text, :default => ''
  end
end
