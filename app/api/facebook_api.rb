# An API for interface withing facebook
# using event machine for making async calls
class FacebookAPI

  def initialize( credentials, identity , current_user = nil  )
    @credentials =  credentials
    @context_name = identity.context.name
    @current_user = current_user
    @fb_url = 'https://graph.facebook.com'
    @fb_batch_size = 50
    @token  = credentials[:token]
    @identity = identity
    @auth = { :query => {"access_token" => @token }}
  end

  # Calls connections in batch, this involves fetching the friends and likes list
  # creating a countdown object and dispatching async requests inside event machine
  # Hands results to the connection handler to write connections to database
  def get_connections
    expected_calls =  ( friends.length   / @fb_batch_size.to_f ).ceil.to_i 
    expected_calls += ( likes.length   / @fb_batch_size.to_f ).ceil.to_i 
    
    @countdown = ConnectionHandler.countdown expected_calls
    @friends_buffer = []
    @likes_buffer = []
    
    Rails.logger.debug "INFO Starting EventMachine"
    EventMachine.run do
      friends.each_slice(@fb_batch_size).map{ |batch| dispatch_friends( batch ) }
      likes.each_slice(@fb_batch_size).map{ |batch| dispatch_likes( batch ) }
    end
    Rails.logger.debug "INFO Stopping EventMachine"

    friends_data = { :context => FriendContext , :connections => @friends_buffer.concat(@old_friends) } 
    likes_data   = { :context => LikeContext, :connections => @likes_buffer }
   
    # Exception data is reported by delayed JOB in the event of an ERROR
    @exception_data = [friends_data,likes_data]
    if (Rails.env != 'production' )  
      Rails.logger.debug "DEBUG Dumping json outputs to tmp/ folder"
      File.open( 'tmp/facebook_friends.json' , 'w' ){ |f| f.write(friends_data.to_json ) }
      File.open( 'tmp/facebook_likes.json' , 'w' ){ |f| f.write( likes_data.to_json ) }
      File.open( 'tmp/facebook_credentials.json' , 'w'){ |f| f.write( @credentials.to_json ) }
    end

    Rails.logger.info "INFO Writing Facebook Friends to DB"
    ConnectionHandler.build_user_user_connections( friends_data , @identity )
    
    Rails.logger.info "INFO Writing Facebook Likes to DB"
    ConnectionHandler.build_user_object_connections( likes_data , @identity )
  end

  # Retreives a list of all the friends (BLOCKING)
  def friends 
    if @new_friends.nil? and @old_friends.nil?
        friends = []
        url  = @fb_url + '/me/friends'
        data = HTTParty.get( url , @auth ).parsed_response
        Rails.logger.info "INFO Retreiving Paginated Facebook IDs"
        while data['data'].length > 0
          friends.concat data['data']
          data = HTTParty.get( data['paging']['next'] , :query=> { 'access_token' => @token  } ).parsed_response
          Rails.logger.info "INFO Retreiving Paginated Facebook IDs"
        end
      @old_friends , @new_friends = remove_persisted( friends )
      Rails.logger.info "INFO DJ_FACEBOOK "\
                        "Friends: #{friends.length}, "\
                        "New: #{@new_friends.length}, "\
                        "Old: #{@old_friends.length}"
    end
    @new_friends
  end
  
  # Retrieves a list of all the friends (BLOCKING)
  def likes
    if @likes.nil? 
      #if @new_likes.nil? and @old_likes.nil?
      likes = []
      Rails.logger.info "INFO Retrieving Paginated Like Ids"
      data = HTTParty.get( @fb_url + '/me/likes', @auth ).parsed_response
      while data['data'].length > 0
        likes.concat data['data']
        data = HTTParty.get( data['paging']['next'] ).parsed_response
        Rails.logger.info "INFO Retrieving Paginated Like Ids"
      end
      @likes = likes
      #@old_likes , @new_likes = remove_persisted( likes)
      #Rails.logger.info "INFO DJ_FACEBOOK "\
                        #"Likes: #{likes.length}, "\
                        #"New: #{@new_likes.length}, "\
                        #"Old: #{@old_likes.length}"
    end
    @likes
  end
  
  # Async HTTP Request function for requesting info on a batch of likes
  # Creating a Connection hash for building a TpObject and passing that to
  # the the likes buffer, will retry three time on error
  def dispatch_likes( batch, tries = 0)
   request = EM::HttpRequest.new( @fb_url ).post( {:body =>{
      :access_token => @token,
      :batch => batch.map{ |like| { :method=>"GET", :relative_url=>like['id'] }}.to_json }})

   request.callback{ 
      if request.response_header.status != 200
        Rails.logger.fatal "FATAL Facebook Like Callback Bad Response code #{request.response_header.status}" 
        Rails.logger.ap request
        raise "Bad Error Code on Request"
      end

      begin
        likes_info = MultiJson.load(request.response).delete_if{|item| item.nil?}.map{ |response| MultiJson.load (response['body'] ) }
      
      connection_info =  likes_info.map{ |object| {
              :entity => {
                :uid => object['id'],
                :context_name => 'facebook',
                :name => object['name'],
                :url => "http://www.facebook.com/#{object['id']}",
                :image => "https://graph.facebook.com/#{object['id']}/picture",
                :properties => {}
              },
              :connection => {
                :from => 'me',
                :to => 'you',
                :properties => {}
              }
            } 
         }
        @likes_buffer.concat( connection_info )
        
        Rails.logger.info "INFO Facebook Like Dispatch Successful - Countdown: #{@countdown.count}"
      rescue Exception => ex
        Rails.logger.fatal "FATAL : Facebook Parse Error for #{context_name}"
        Rails.logger.fatal "FATAL : Facebook Parse Error #{ex.message}"
        Rails.logger.fatal "FATAL : Facebook Parse Error Backtrace ... "
        ex.backtrace[0..10].each{ |trace| Rails.logger.fatal trace} 
        Rails.logger.fatal "FATAL Error Reading the response #{@countdown.count}"
        Rails.logger.ap request.response
      ensure
        stop_if_finished 
      end
   }

   request.errback {
      if tries <= 3 
        Rails.logger.warn "WARN Facebook Likes Request Failed #{@countdown.count}, Trying Again"
        dispatch_likes( likes , tries +1)
      else
        Rails.logger.fatal "FATAL Facebook Likes Request Failed #{@countdown.count}, Giving Up"
        stop_if_finished
      end
   }
  end

  # Async HTTP request function for requesting info on a batch of friends
  # Creates a connection with OAuth2 token and on callback builds hash to 
  # append the the friends_buffer. 
  # Will repeat 3 times on error
  def dispatch_friends( batch , tries = 0 ) 
    request = EM::HttpRequest.new( @fb_url ).post({:body=>{ 
        :access_token => @token, 
        :batch => batch.map{ |friend| { :method=>"GET", :relative_url=>friend['id'] }}.to_json }})

    request.callback{
      if request.response_header.status !=200
        Rails.logger.fatal "FATAL Facebook Friends Unexpected Response Code #{request.response_header.status}"
        Rails.logger.ap request
        raise "Bad Error Code on Request"
      end

      begin
        friend_info = MultiJson.load(request.response).delete_if{|item| item.nil? }.map{ |response| MultiJson.load(response['body']) }
        connection_info = friend_info.map{ |friend| {
            :identity => { 
              :uid => friend['id'],
              :context_name=> 'facebook',
              :credentials => {},
              :name => friend['name'],
              :image => "https://graph.facebook.com/#{friend['id']}/picture",
              :url => friend['link'],
              :properties => {}
              },
            :email => nil,
            :connection => FriendConnection
           }
          }
        @friends_buffer.concat( connection_info )
        Rails.logger.info "INFO Facebook Friend Dispatch Successful - Countdown: #{@countdown.count}"
      rescue Exception => ex
        Rails.logger.fatal "FATAL : Facebook Parse Error for #{context_name}"
        Rails.logger.fatal "FATAL : Facebook Parse Error #{ex.message}"
        Rails.logger.fatal "FATAL : Facebook Parse Error Backtrace ... "
        ex.backtrace[0..10].each{ |trace| Rails.logger.fatal trace} 
        Rails.logger.fatal "FATAL Failed to Read Facebook Error Request"
        Rails.logger.ap request.response 
      ensure
        stop_if_finished
      end
    }

    request.errback{
      if tries <= 3
         Rails.logger.error "ERROR Facebook Friend Request Errored #{@countdown.count}, Trying Again"
        dispatch_friends( batch  , tries+1 )
      else
        Rails.logger.fatal "FATAL Facebook Friend Request Errored #{@countdown.count}, Giving Up"
        stop_if_finished
      end
    }
  end

  # Helper that decrements the countdown and stops the EM Reactor if we have
  # have no pending requests
  def stop_if_finished 
        EM.stop if @countdown.minus_one == 0
  end

  # Constant hash to help build a likes ConnectionContext
  LikeContext =   { :name  => 'facebook-like' }

  # Constant hash to help buld a Friend ConnectionContext
  FriendContext = { 
    :name  => 'facebook-friendship' }

  # Constant hash to help build a Friend Connection 
  FriendConnection = { 
  :from => 'me', 
  :to => 'you', 
  :properties => {} }

  # Gets the attributes 
  def get_attributes( raw_info )

    expected_calls = (raw_info[:work].length / @fb_batch_size.to_f).ceil.to_i
    expected_calls +=  (raw_info[:education].length / @fb_batch_size.to_f).ceil.to_i
    @workplace_buffer = []
    @education_buffer = []
    if expected_calls == 0
      return { :facebook_workplaces => @workplace_buffer, :facebook_education => @education_buffer}
    end
    @countdown = ConnectionHandler.countdown(expected_calls)
    
    EventMachine.run do
      raw_info[:work].map{|work| work.deep_symbolize_keys }.each_slice(@fb_batch_size).each{ |batch| dispatch_workplaces(batch) }
      raw_info[:education].map{|edu| edu.deep_symbolize_keys }.each_slice(@fb_batch_size).each{ |batch| dispatch_education(batch) }
      #dispatch_cover_photo
    end

    if Rails.env != 'production'
      Rails.logger.debug "DEBUG: tmp/facebook_<info> has been written to for reference"
      File.open( 'tmp/facebook_work.json' , 'w' ){ |f| f.write( @workplace_buffer.to_json ) }
      File.open( 'tmp/facebook_edu.json' , 'w' ){ |f| f.write( @education_buffer.to_json ) }
      File.open( 'tmp/facebook_credentials.json' , 'w'){ |f| f.write( @credentials.to_json )} 
    end
   
    return { :facebook_workplaces => @workplace_buffer, :facebook_education => @education_buffer}
  end

  def dispatch_education( batch, tries = 0 )
    request = EM::HttpRequest.new(@fb_url).post( { :body => { 
      :access_token => @token,
      :batch => batch.map{ |edu| { :method=> "GET" , :relative_url =>edu[:school][:id] }}.to_json }})

      request.callback do
        Rails.logger.info "INFO Facebook Request Status #{request.response_header.status}"
        if request.response_header.status != 200
          Rails.logger.fatal "FATAL Facebook Request Failed"
          Rails.logger.ap request
          raise "Batch Process Failed #{@countdown.count}"
        end
           
        begin
          data = MultiJson.load( request.response)
                                .delete_if{ |item| item.nil? }
          raise "Bad Response " if data.map{|item| item['code']!=200}.any?
          
          educations = data.map{  |response| MultiJson.load(response['body']).deep_symbolize_keys } 
          
          @education_buffer.concat(educations.zip( batch )
                    .map{ |school,education| 
                      { :school => {
                        :uid => school[:id],
                        :context_name => :facebook,
                        :name => school[:name],
                        :image => "https://graph.facebook.com/#{school[:id]}/picture",
                        :url => school[:link],
                        :properties => school.keep_if{ |key| %w(phone about website likes category).include? key }
                      },
                      :classyear => education.has_key?(:year) ? education[:year][:name] : '?',
                      :station => education[:type],
                      :majors => education.has_key?(:concentration) ? education[:concentration].map{ |major|  major[:name] } : []
                      }  
                    }
                  )
          Rails.logger.info "INFO Facebook Education Dispatch Successful #{@countdown.count}"
        rescue Exception => ex
          Rails.logger.fatal "FATAL : Facebook Parse Error for "
          Rails.logger.fatal "FATAL : Facebook Parse Error #{ex.message}"
          Rails.logger.fatal "FATAL : Facebook Parse Error Backtrace ... "
          ex.backtrace[0..10].each{ |trace| Rails.logger.fatal trace} 
          Rails.logger.fatal "FATAL Error Processing Facebook Education Request for"\
                       "#{ batch.map{|edu| edu[:school][:id] }.to_s }"
          Rails.logger.ap request.response
        ensure
          stop_if_finished 
        end
      end

      request.errback{
      if tries <= 3
        Rails.logger.error "ERROR Facebook Education Failed, Trying Again #{@countdown.count}"
        dispatch_education( batch  , tries+1 )
      else
        Rails.logger.fatal "FATAL Facebook Education Failed 3 Times, Giving Up #{@countdown.count}"
        stop_if_finished
      end
    } 
  end

  def dispatch_workplaces( batch, tries = 0 )
    request = EM::HttpRequest.new(@fb_url).post( { :body => { 
      :access_token => @token,
      :batch => batch.map{ |work| { :method=> "GET" , :relative_url =>work[:employer][:id] }}.to_json }})

      request.callback do
        Rails.logger.info "INFO Facebook Workplace Request Status #{request.response_header.status}"
        if request.response_header.status != 200
          Rails.logger.fatal "FATAL Facebook Workplace Request Failed"
          Rails.logger.ap request
          raise "Facebook Process Failed #{@countdown.count}"
        end
           
        begin
          data = MultiJson.load( request.response)
                                .delete_if{ |item| item.nil? }
          raise "Bad Response " if data.map{|item| item['code']!=200}.any?
          
          workplaces = data.map{  |response| MultiJson.load(response['body']).deep_symbolize_keys } 
          
          @workplace_buffer.concat( workplaces.zip(batch).map{ |(place, work)| {
              :workplace => {
                :uid => place[:name],
                :context_name => 'credport_workplace_context',
                :name => place[:name],
                :image => "https://graph.facebook.com/#{place[:id]}/picture",
                :url => place[:link],
                :properties => place.keep_if{ |key| %w(description industry company_overview mission about founded phone link).include? key }
              },
              :title => (work[:position] and work[:position][:name]) ? work[:position][:name] : "Employee" ,
              :summary => work[:description],
              :from => self.class.transform_date(work[:start_date]),
              :to => work.has_key?(:end_date) ? self.class.transform_date(work[:end_date]) : {},
              :current => work.has_key?(:end_date) ? false : true
            } } )

          Rails.logger.info "INFO Facebook Workplace Dispatch Successful  #{@countdown.count}"
        rescue Exception => ex
          Rails.logger.fatal "FATAL : Facebook Parse Error for "
          Rails.logger.fatal "FATAL : Facebook Parse Error #{ex.message}"
          Rails.logger.fatal "FATAL : Facebook Parse Error Backtrace ... "
          ex.backtrace[0..10].each{ |trace| Rails.logger.fatal trace} 
          Rails.logger.fatal "FATAL Error Processing Facebook Workplace Request for"\
                       "#{ batch.map{|work| work[:employer][:id] }.to_s }"
          Rails.logger.ap request.response
        ensure
          stop_if_finished 
        end
      end

      request.errback{
      if tries <= 3
        Rails.logger.error "ERROR Facebook Workplace Failed, Trying Again #{@countdown.count}"
        dispatch_workplaces( batch  , tries+1 )
      else
        Rails.logger.fatal "FATAL Facebook Workplace Failed 3 Times, Giving Up #{@countdown.count}"
        stop_if_finished
      end
    } 
  end

  def self.transform_date( date )
    return {} if date.nil? 
    date = date.split('-')
    case date.length
    when 0 
      {}
    when 1
      {:year => date.first}
    when 2
      {:year => date.first, :month => date[1]}
    when 3
      {:year => date.first, :month => date[1], :day => date[2]}
    else
      {}
    end
  end
  
  def remove_persisted( ids) 
      
      query = ids.map{|id| {:context_name => @context_name,:uid => id["id"]}}
      
      persisted_id = Identity.batch_exists(query)
      new_ids = ids.zip(persisted_id)                      \
                   .select{|id,persisted| not persisted }  \
                   .map{|id,persisted| id }
      
      old_ids = query.zip(persisted_id)                    \
                   .select{|query,persisted| persisted}    \
                   .map{|query,persisted| {
                      :identity =>  query, 
                      :connection => FriendConnection
                     }
                    }
      [old_ids, new_ids]
  end

end

