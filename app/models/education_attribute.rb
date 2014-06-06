class EducationAttribute < ActiveRecord::Base
  attr_accessible :classyear, :majors, :station, :added_by, :user, :school, :visible
  serialize :majors

  belongs_to :school, :class_name => "Entity", :foreign_key => :school_id
  belongs_to :added_by, :class_name => "Application", :foreign_key => :added_by
  belongs_to :user, :touch => true
  
  validates :user, :presence => true
  validates :school, :presence => true
  validates :added_by, :presence => true
  validates :station, :presence => true, :uniqueness => {:scope => [:school_id, :user_id]}
  validates :classyear, :presence => true
  validates :majors, :presence => true, :unless => Proc.new { |x| x.majors.is_a?(Array) && x.majors.empty? }

  def classyear_string
    classyear == "?" ? "" : "Class of #{classyear}"
  end

  def key
    station
  end

  def value
    school.name
  end

  def set_public
    self.visible = true
    self.save
  end

  def set_private
    self.visible = false
    self.save
  end

  def self.anonymous_school
    Entity.find_by_uid_and_context_name('Anonymous_School', 'credport_entity_context')
  end

  def school_scoped
    visible ? school : self.class.anonymous_school
  end
end
