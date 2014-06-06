class User < ActiveRecord::Base
  include NeoNode

  attr_accessible :password, :password_confirmation, :name
  attr_accessor :password, :password_confirmation
  
  has_many :emails, :conditions => {:verification_code => nil}, :dependent => :destroy
  has_many :emails_to_verify, :class_name => "Email", :foreign_key => :user_id, :conditions => "verification_code IS NOT NULL", :dependent => :destroy

  has_many :phones, :conditions => {:verification_code => nil}, :dependent => :destroy
  has_many :phones_to_verify, :class_name => "Phone", :foreign_key => :user_id, :conditions => "verification_code IS NOT NULL", :dependent => :destroy

  has_many :websites, :conditions => {:verification_code => nil}, :dependent => :destroy
  has_many :websites_to_verify, :class_name => "Website", :foreign_key => :user_id, :conditions => "verification_code IS NOT NULL", :dependent => :destroy

  has_many :identities, :after_add => :connect_via_neo4j, :dependent => :destroy
  has_many :profile_pictures
  has_many :education_attributes, :dependent => :destroy
  has_many :work_attributes, :dependent => :destroy
  
  has_many :posts
  has_many :applications

  validates_confirmation_of :password
  validates_presence_of :password, :on => :create
  validates_presence_of :name
  before_save :encrypt_password
  after_save :clear_background_picture

  after_save :set_mixpanel_attributes
  after_touch :set_mixpanel_attributes

  # after_create :create_credport_identity
  after_save :update_credport_identity

  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    end
  end

  def clear_background_picture
    if self.background_picture_changed? and old = self.background_picture_was
      match = old.match /https?:\/\/(.*)\/(.*)/
      if match[1] == "credport-backgroundpictures.s3.amazonaws.com"
        storage = Fog::Storage.new( :provider => 'AWS',
                            :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'], 
                            :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
                            :region => 'us-east-1' )
        directory = storage.directories.get( 'credport-backgroundpictures' )
        remote_file = directory.files.get( URI.unescape match[2] )
        remote_file.destroy

      end
    end
  end

  def connect_via_neo4j(identity)
    neo.execute_query("
      START identity=node:nodes_index(id = {identity}), user=node:nodes_index(id = {user})
      CREATE UNIQUE user-[:identity]->identity ",
      {
        :identity => identity.neo_id,
        :user => self.neo_id
        }) if identity.persisted?
  end

  def create_credport_identity
    identity = Identity.new({
      :uid => self.to_param,
      :name => self.name.empty? ? "Anonymous User" : self.name,
      :url => Rails.application.routes.url_helpers.user_url(self, :host => 'credport.org', :protocol => 'http'),
      :image => self.image,
      :context => IdentityContext.find_by_name(:credport)
      })
    identity.user = self
    identity.save!
  end

  def update_credport_identity

    # self.credport_identity.update_attributes({
    #   :uid => self.to_param,
    #   :name => self.name.empty? ? "Anonymous User" : self.name,
    #   :url => Rails.application.routes.url_helpers.user_url(self, :host => 'credport.org', :protocol => 'https'),
    #   :image => self.image,
    #   :context => IdentityContext.find_by_name(:credport)
    #   })
  end

  # Querying
  def self.find_by_identity(uid, context_name)
    identity = Identity.includes(:user).find_by_uid_and_context_name(uid, context_name)
    identity.nil? ? nil : identity.user
  end

  def self.find_by_email(email)
    email = Email.find_by_email email
    email ? email.user : nil
  end

  def self.find_by_md5_hash(emailhash)
    email = Email.find_by_md5_hash emailhash
    email ? email.user : nil
  end

  def self.authenticate(email, password)
    user = self.find_by_email email
    user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt) ? user : nil
  end

# Attributes
  def first_name
    self.name.split(' ').first
  end
  
  def credport_identity
    credport_identity = self.identities.find_by_context_id IdentityContext.find_by_name :credport
    credport_identity = self.create_credport_identity unless credport_identity
    credport_identity
  end

  def third_identities
    self.identities.where 'context_id not in (?)', IdentityContext.find_by_name(:credport)
  end

  def image
    image = profile_pictures.first.url if profile_pictures.count > 0
    if image.nil?
      image = ActionController::Base.asset_host + ActionController::Base.helpers.asset_path("user.png")
      image = 'http://localhost:5000/' + ActionController::Base.helpers.asset_path("user.png") if Rails.env == 'development'
    end
    image
  end

  def add_education(edu, application_name)
    school = Entity.find_or_create!(edu[:school])
    EducationAttribute.create edu.except!(:school).merge({:added_by => Application.find_by_name(application_name), :user => self, :school => school})
  end

  def add_workplace(work, application_name)
    ap work[:workplace]
    workplace = Entity.find_or_create!(work[:workplace])
    WorkAttribute.create work.except!(:workplace).merge({:added_by => Application.find_by_name(application_name), :user => self, :workplace => workplace})
  end

  def reviews
    Connection.
      joins(:to_identity, :context => :connection_context_protocols)
      .includes(:from)
      .includes(:to)
      .includes(:context)
      .where(:to_id => self.identities, :context_id => ConnectionContext.where({:connection_context_protocols => {:name => 'text-protocol'}}) )
  end

  def credport_recommendation_written_by(writer)
    reviews = Recommendation.where(:recommender_id => writer.credport_identity, :recommended_id => self.credport_identity)
  end

  def credport_review_written_by(writer)
    reviews = Connection.where(:from_id => writer.credport_identity, :to_id => self.credport_identity, :context_id => ConnectionContext.where({:name => %w{credport_friend_recommendation credport_colleague_recommendation credport_family_recommendation credport_other_recommendation}})
    )
  end

  def credport_recommendations_to_approve
    Recommendation.where :recommended_id => self.credport_identity, :connection_in_db_id => nil
  end

  def to_param
    (id+100000).to_s(16).reverse
  end

  def serializable_hash(options = {})
    hash = super(options)
    hash['id'] = to_param
    hash.delete 'password_hash'
    hash.delete 'password_salt'
    hash.delete 'created_at'
    hash.delete 'updated_at'
    hash
  end
  def self.find_by_param(param)
    self.find_by_id(param.reverse.to_i(16)-100000) if param
  end

  def self.find_param(param)
    self.find(param.reverse.to_i(16)-100000)
  end


# tracking
  def mixpanel
    @mixpanel = Mixpanel::Tracker.new Rails.configuration.mixpanel_key, {}
  end

  def set_mixpanel_attributes
    # set which identities are connected
    setting_hash = {}
    self.identities.each{ |identity| setting_hash[identity.context.name] = 'true'}

    mixpanel.set(self.to_param, {
      :'$ip' => '',
      :name => self.name,
      :param => self.to_param,
      :created => self.created_at,
      :identities => self.identities.count,
      :photos => self.profile_pictures.count,
      :reviews => self.reviews.count
      }.merge(setting_hash), {})
    mixpanel.set(self.to_param, {
      :email => self.emails.first.email
      }) unless self.emails.empty?

  end

  def mixpanel_set(props = {}, params = {})
    mixpanel.delay(:queue => 'mixpanel').set self.to_param, props, params
  end

  def mixpanel_increment(props = {}, params = {})
    mixpanel.delay(:queue => 'mixpanel').increment self.to_param, props, params
  end

  def mixpanel_track(event, props = {}, params = {})
    props.merge!({:distinct_id => self.to_param, :mp_name_tag => "#{self.to_param} - #{self.name}" })
    mixpanel.delay(:queue => 'mixpanel').track event, props, params
  end

# actions

  def request_recommendation_by_email(email)
    
  end
end
