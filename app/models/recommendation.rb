class Recommendation < ActiveRecord::Base
  attr_accessible :recommended, :recommender, :role, :text

  belongs_to :connection_in_db, :class_name => 'Connection', :foreign_key => :connection_in_db_id

  belongs_to :recommended, :class_name => "Identity", :foreign_key => :recommended_id
  belongs_to :recommender, :class_name => "Identity", :foreign_key => :recommender_id

  validates_associated :recommended
  validates_associated :recommender

  validates :recommended, :presence => true
  validates :recommender, :presence => true
  validates :role, :presence => true, :inclusion => { :in => ['credport_friend_recommendation', 'credport_colleague_recommendation', 'credport_family_recommendation', 'credport_other_recommendation'] }
  validates :text, :presence => true


  def approve
    if connection_in_db.nil?
      begin
        con = self.create_connection_in_db!({
          :from => recommender,
          :to => recommended,
          :context => ConnectionContext.find_by_name(role),
          :properties => {
            :text => text
          }
          })
        self.save!
        true
      rescue Exception => e
        false
      end
    else
      # already approved
      true
    end
  end

  def serializable_hash(options = {})
    options = { 
      :include => [:recommender, :recommended], 
      :only => [:role, :text, :approved]
    }.update(options)
    super(options)
  end
end
