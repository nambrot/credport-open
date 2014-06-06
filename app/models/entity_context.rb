class EntityContext < ActiveRecord::Base
  attr_accessible :name, :properties, :application, :title
  store :properties

  validates :name, :presence => true, :uniqueness => true
  validates :title, :presence => true

  belongs_to :application
  validates_associated :application
  
  has_many :entities, :foreign_key => :context_id
end
