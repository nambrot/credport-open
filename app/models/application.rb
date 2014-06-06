class Application < ActiveRecord::Base
  attr_accessible :name, :entity, :redirect_uri, :entity_attributes
  
  has_many :connection_contexts
  has_many :identity_contexts
  has_many :entity_contexts
  belongs_to :entity
  accepts_nested_attributes_for :entity

  belongs_to :user

  validates :name, :presence => true, :uniqueness => true
  validates_associated :entity, :if => :not_credport
  validates :redirect_uri, :presence => true, :redirect_uri => true
  def not_credport
    name != 'credport'
  end

  # Doorkeeper related stuff
  has_one :doorkeeper_application, :class_name => "Doorkeeper::Application"
  after_create :create_doorkeeper_application_callback

  def create_doorkeeper_application_callback
    self.create_doorkeeper_application!(:name => self.name, :redirect_uri => self.redirect_uri)
  end

  after_save :save_redirect_uri
  def save_redirect_uri
    self.doorkeeper_application.update_attribute :redirect_uri, self.redirect_uri
  end

end
