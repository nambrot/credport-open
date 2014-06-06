class IdentityContext < ActiveRecord::Base
  attr_accessible :name, :properties, :application, :title
  store :properties

  validates :name, :presence => true, :uniqueness => true
  validates :title, :presence => true

  belongs_to :application
  validates_associated :application
  has_many :identities,  :foreign_key => :context_id

  def serializable_hash(options = {})
    options = { 
      :only => [:name, :title]
    }.update(options)
    super(options)
  end
end
