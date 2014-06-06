class Entity < ActiveRecord::Base
  include NeoNode
  attr_accessible :credentials, :image, :properties, :uid, :url, :name, :context, :context_name
  store :credentials
  store :properties

  belongs_to :context, :class_name => "EntityContext", :foreign_key => :context_id
  validates_associated :context
  validates :context, :presence => true
  
  validates :uid, :presence => true, :uniqueness => { :scope => :context_id }
  validates :url, :presence => true
  validates :image, :presence => true
  validates_format_of :image, :with => URI::regexp(%w(http https))
  validates_format_of :url, :with => URI::regexp(%w(http https))
  validates :name, :presence => true
  

  def context_name=(context_name)
    self.context = EntityContext.find_by_name context_name
  end

# Querying
  def self.find_or_create(attributes)
    begin
      self.find_or_create!(attributes)
    rescue
      nil
    end
  end

  def self.find_or_create!(attributes) #assumes context_name instead of context
    self.find_by_uid_and_context_name(attributes[:uid], attributes[:context_name]) || self.create!(attributes)
  end

  def self.find_by_uid_and_context(uid, context)
    self.includes(:context).merge(context).find(:first, :conditions => {:uid => uid})
  end

  def self.find_by_uid_and_context_name(uid, context_name)
    self.find_by_uid_and_context(uid, EntityContext.where(:name => context_name))
  end
end
