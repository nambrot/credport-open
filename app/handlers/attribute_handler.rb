=begin rdoc
  AttributeHandler writes Attributes to the database
  Given an attributes hash, the current user and a provider
  It creates a tpsubidenity and manages then adds the appropriate attributes
=end
class AttributeHandler

=begin rdoc
  Get Attributes, will takes the credentials and provider and make additional request 
  other than those raw info ones to fetch attribute information.  That information is
  written with write_attributes method

  * *Args* :
  -usertp : The current Users TPSUBID associated with the attributes
  -current_user -> current user object
  -o : The omniauth hash returned by the strategy
  -provider -> provider that owns the information belongs to 
  * *Returns*: Nothing
=end
  def self.get_attributes(identity, current_user, o, provider)
    data = {}
    case provider
      when 'facebook'
        data = FacebookAPI.new( o[:credentials] , identity ).get_attributes(o[:extra][:raw_info]) 
      when 'linkedin'
        if o[:extra][:raw_info].has_key?(:positions)
          data = LinkedinAPI.new( o[:credentials], identity )
                            .get_attributes(o[:extra][:raw_info][:positions][:values]) 
        end
      when 'twitter'
        #data = TwitterAPI.new( o['credentials'], usertp ).get_attributes ; 
      when 'ebay'
        #
      when 'paypal'
        #
      when 'xing'
        # 
      else
        Rails.logger.fatal "Invalid provider, #{provider}"
        raise "Invalid provider"
    end

    o[:extra].merge!(data)
    write_attributes( identity, current_user, o, provider )
  end 

=begin rdoc
  Write Attribute will take the updated O hash and write attributes to the DB

  * *Args* :
  -usertp : The TPSUBID associated with the current user / attributes
  -current_user -> current user object
  -o : The omniauth hash returned by the strategy
  -provider -> provider that owns the information belongs to 

  * *Returns*: Nothing
=end
  def self.write_attributes( identity , current_user, o , provider) 
    start = Time.now().to_f
    puts "Attributes Handler Started"
    
    if o[:extra].has_key?(:name) and current_user.name == 'Anonymous User'
      current_user.name = o[:extra][:name]
      current_user.save
    end

    if o[:extra].has_key?(:tagline) and current_user.tagline == ''
      current_user.tagline = o[:extra][:tagline]
      current_user.save
    end
  
    # Add profile picture
    current_user.profile_pictures.create(:url => o[:info][:image]) if o[:info].has_key? :image

    case provider
      when 'facebook'
        add_facebook_attributes( o[:extra], identity, current_user ,provider)
      when 'linkedin'
         add_linkedin_attributes( o[:extra], identity , current_user ,provider)
      when 'twitter'
        add_twitter_attributes( o[:extra] , identity, current_user, provider )
      when 'ebay'
        add_ebay_attribtues( o[:extra], identity, current_user, provider )
      else
    end
    
    Rails.logger.info "INFO Attribute Updated for User #{current_user.id} #{provider}"\
                      " in #{(Time.now().to_f-start)*1000} ms"
  end    
  
=begin rdoc
  Adds the workplaces and education from the facebook api

  * *Args*: 
    attributes -> The facebook attribute hash
    usertp -> The facebook tp to associate with the attributes
    current_user -> The Current user object
    provider -> the provider object that the information came from, expect facebook

  * *Returns*: Nothing
=end
  def self.add_facebook_attributes( attributes , usertp, current_user ,provider)

    # facebook workplace
    attributes[:facebook_workplaces].each{ |work| self.add_workplace(current_user, work, provider)}
    attributes[:facebook_education].each{ |edu| self.add_education(current_user, edu.deep_symbolize_keys , provider )}

  end

=begin rdoc
  Adds the workplaces and education from the linkedin api

  * *Args*: 
    attributes -> The facebook attribute hash
    usertp -> The linkedin tp to associate with the attributes
    current_user -> The Current user object
    provider -> the provider object that the information came from, expect linkedin

  * *Returns*: Nothing
=end
  def self.add_linkedin_attributes( attributes , usertp, current_user ,provider)
    
    attributes[:workplaces].each{ |work| self.add_workplace( current_user, work, provider ) }
    attributes[:education].each{ |edu| edu.deep_symbolize_keys; self.add_education( current_user, edu.deep_symbolize_keys , provider ) }

  end

=begin rdoc
  No attributes associated with twitter as of yet
=end
  def self.add_twitter_attributes( attributes , usertp , current_user , provider )
  
  end

=begin rdoc
  No attributes associated with twitter as of yet
=end
  def self.add_ebay_attribtues( attributes , usertp , current_user , provider )
  
  end

=begin rdoc

Add Workplace for a given user, work hash and provider
This is provider agnostic, i.e it doesn't depend on the provider
so long as the work hash contains properties required

Uses the user.add_workplace method and therefore is abstracted from
and low level implementation

* *Args*  :
  - current_user -> Current user Object
  - work -> Hash representing the work attribute
  - providername -> The name of the provider

* *Returns* : A Workplace Attribute that is created

=end
  def self.add_workplace( current_user, work, application_name )
    current_user.add_workplace(work, application_name)
  end

=begin rdoc

Add Education for a given user, edu hash and provider
This is provider agnostic, i.e it doesn't depend on the provider
so long as the edu hash contains properties required

Uses the user.add_education method and therefore is abstracted from
and low level implementation

* *Args*  :
  - current_user -> Current user Object
  - edu -> Hash representing the education attribute
  - providername -> The name of the provider

* *Returns* : The EducationAttribute object that is created

=end
  def self.add_education( current_user, edu , application_name )
    current_user.add_education(edu, application_name)
  end
end
