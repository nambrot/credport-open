class Identity < ActiveRecord::Base
  include NeoNode
  attr_accessible :image, :properties, :uid, :url, :name, :context, :context_name, :credentials, :subtitle
  store :credentials
  store :properties

  belongs_to :user, :touch => true
  belongs_to :context, :class_name => "IdentityContext", :foreign_key => :context_id
  validates_associated :context
  validates :context, :presence => true

  has_many :to_edges, :class_name => 'Connection', :foreign_key => :to_id, :as => :to
  has_many :from_edges, :class_name => "Connection", :foreign_key => :from_id, :as => :from

  before_destroy :destroy_associated_connections

  validates :uid, :presence => true, :uniqueness => { :scope => :context_id }
  validates :url, :presence => true
  validates :image, :presence => true
  validates_format_of :image, :with => URI::regexp(%w(http https))
  validates_format_of :url, :with => URI::regexp(%w(http https))
  validates :name, :presence => true

  def context_name=(context_name)
    self.context = IdentityContext.find_by_name context_name
  end

  def destroy_associated_connections
    to_edges.map(&:destroy)
    from_edges.map(&:destroy)
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

  def self.find_or_try_create(attributes)
    ret = self.find_by_uid_and_context_name(attributes[:uid], attributes[:context_name]) if attributes and attributes[:uid] and attributes[:context_name]
    ret = self.create(attributes) if ret.nil?
    return ret
  end

  def self.batch_find(array_of_attributes)
    Identity.transaction do
      array_of_attributes.map { |node| Identity.find_by_uid_and_context_name(node[:uid], node[:context_name]) }
    end
  end

  def self.batch_find_or_create(array_of_attributes)
    Identity.transaction do
      array_of_identities = array_of_attributes.map { |node| Identity.find_by_uid_and_context_name(node[:uid], node[:context_name]) }

      array_of_nodes_to_create = array_of_identities.zip(array_of_attributes).inject([]) { |newarray, (identity, node)| newarray << node unless identity; newarray }
      array_of_raw_nodes = array_of_nodes_to_create.uniq{|node| [node[:uid], node[:context_name]]}.map { |node| Identity.create! node.merge({:ignore_neo => true}) }

      self.batch_create_neo4j_nodes(array_of_raw_nodes)
      
      index = Hash[*array_of_identities.compact.concat(array_of_raw_nodes).collect{|identity| [identity.uid.to_s + identity.context.name, identity]}.flatten]

      array_of_attributes.map { |node| index[node[:uid].to_s + node[:context_name].to_s] }
    end
  end

  def self.find_by_uid_and_context(uid, context)
    self.includes(:context).merge(context).find_by_uid(uid.to_s)
  end

  def self.find_by_uid_and_context_name(uid, context_name)
    self.find_by_uid_and_context(uid, IdentityContext.where(:name => context_name))
  end

  def self.batch_exists(array_of_attributes)
    self.batch_find(array_of_attributes).map{|id| !id.nil? }
  end

# fetch stuff
  def fetch_attributes
  end

  def fetch_connections(credentials)
    begin
      ConnectionHandler.perform(credentials, uid, context.name)
    rescue Exception => ex
      Rails.logger.fatal %("FATAL : DJ_FETCH_CONNECTIONS Error for #{context.name}
      Message:  #{ex.message}
      Backtrace #{ex.backtrace[0..10].join('\n')}")
      if !@exception_data.nil?
        Rails.logger.info "WARN : Delayed Job Error Retrieved Exception Data"
        Rails.logger.ap @exception_data
      else
        Rails.logger.warn "INFO : No Exception Data Retreived"
      end
      raise "DJ_FAILED"
    ensure
      self.touch
    end
  end

  def serializable_hash(options = {})
    options = { 
      :include => [:context], 
      :only => [:name, :uid, :image, :url]
    }.update(options)
    super(options)
  end
end
