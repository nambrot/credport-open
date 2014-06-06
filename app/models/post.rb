class Post < ActiveRecord::Base
  attr_accessible :body, :title, :summary
  
  belongs_to :user
  validates :body, :presence => true
  validates :title, :presence => true

  def to_param
    "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}"
  end
end
