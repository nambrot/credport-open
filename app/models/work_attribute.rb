class WorkAttribute < ActiveRecord::Base
  attr_accessible :added_by, :current, :from, :summary, :title, :to, :user, :workplace
  store :from
  store :to

  belongs_to :workplace, :class_name => 'Entity', :foreign_key => :workplace_id
  belongs_to :user, :touch => true
  belongs_to :added_by, :class_name => 'Application', :foreign_key => :added_by
  # validate from/to

  validates :user, :presence => true
  validates :workplace, :presence => true
  validates :added_by, :presence => true
  validates :title, :presence => true, :uniqueness => {:scope => [:workplace_id, :user_id]}
  
  def key
    "Work"
  end

  def value
    "#{title} at #{workplace.name}"
  end

  def self.anonymous_workplace
    Entity.find_by_uid_and_context_name('Anonymous_Workplace', 'credport_entity_context')
  end

  def workplace_scoped
    visible ? workplace : self.class.anonymous_workplace
  end

  def set_public
    self.visible = true
    self.save
  end

  def set_private
    self.visible = false
    self.save
  end

  NO_YEAR = 0
  ONLY_YEAR = 1
  YEAR_MONTH = 2
  
  def date_string
    
    humanized_date = ""
    begin
      if from.nil? or to.nil? or (to.empty? and from.empty?)
        return humanized_date
      end
        
      # Determine the date_from state
      date_from = 0
      if from.empty? or (from[:month]=="00" and from[:year]=="0000") 
         date_from = NO_YEAR
      elsif from[:year]!="0000" and !from[:year].nil?
         date_from = ONLY_YEAR
         if from[:month]!="00" and !from[:month].nil?
            date_from = YEAR_MONTH
         end
      end

      # Detemine date_to State
      date_to = 0
      if to.empty? or (to[:month]=="00" and to[:year]=="0000") 
         date_to = NO_YEAR
      elsif to[:year]!="0000" and !to[:year].nil?
         date_to = ONLY_YEAR
         if to[:month]!="00" and !to[:month].nil?
            date_to = YEAR_MONTH 
         end
      end
     
      
      # Generate 0-8 possibitiies
      date_to *=3 
      case date_to+date_from
        
        when 0 
          # No year info
          humanized_date = ""
        when 1 
          # Only from year
          humanized_date = current ? "Since #{from[:year]}" : from[:year]
        when 2 
          # Only from year and from month
          month = Date::MONTHNAMES[Integer(from[:month])]
          humanized_date = current ? "Since #{month} #{from[:year]}" : from[:year]
        when 3 
          # Only to year
          humanized_date = "Until #{to[:year]}"
        when 4 
          # To year + from year
          humanized_date = "#{from[:year]} to #{to[:year]}"
        when 5 
          # To year + from year+month
          humanized_date = "#{from[:year]} to #{to[:year]}"
        when 6
          # Only to year + month information
          month = Date::MONTHNAMES[Integer(to[:month])]
          humanized_date = "Until #{month} #{to[:year]}"
        when 7
          # Only to year + month and From year (drop all month info)
          humanized_date = "#{from[:year]} to #{to[:year]}"
        when 8
          # All from/to year and month
          from_month = Date::MONTHNAMES[Integer(from[:month])]
          to_month = Date::MONTHNAMES[Integer(to[:month])]
          humanized_date = "#{from_month} #{from[:year]} to #{to_month} #{to[:year]}"
        else
          # this else should never happen
          humanized_date = ""
      end
  rescue
     humanized_date = ""
   end
    humanized_date
  end
end
