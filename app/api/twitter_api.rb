require 'em-http/middleware/oauth'

# Twitter API with EventMachine for Async calls
class TwitterAPI

  # Given credentials we can create a user specific OAuth API object
  def initialize( credentials, identity, current_user = nil )
    @credentials = credentials 
    @current_user = current_user
    @twitter_url  = 'https://api.twitter.com'
    @twitter_batch_size = 90 
    @token = credentials[:token]
    @secret = credentials[:secret]
    @context_name = identity.context.name
    @identity = identity
    @auth = { :query => {:access_token => @token }}
    @oauth_config  = {
        :consumer_key => Rails.configuration.api_keys['twitter']['consumer_key'],
        :consumer_secret => Rails.configuration.api_keys['twitter']['consumer_secret'],
        :access_token => @token,
        :access_token_secret => @secret
       }
  end
  
  # Gets IDs, then connection information and pass this to the database
  def get_connections
    @followers_buffer = []
    @friends_buffer = []

    batch_connections

    friends_data = { :context => TwitterContext , :connections => @friends_buffer.concat(@old_friends)  }
    followers_data = { :context => TwitterContext , :connections => @followers_buffer.concat(@old_followers)  }

    @exception_data= [ friends_data, followers_data ]
    if Rails.env != 'production'
      Rails.logger.debug "DEBUG Dumping Twitter Data to tmp/ folder"
      File.open( 'tmp/twitter_friends.json' , 'w'){ |f| f.write( friends_data.to_json ) }
      File.open( 'tmp/twitter_followers.json' , 'w'){ |f| f.write( followers_data.to_json ) }
      File.open( 'tmp/twitter_credentials.json', 'w'){ |f| f.write( @credentials ) }
    end
  
    Rails.logger.info "INFO writing Twitter Friends Data"
    ConnectionHandler.build_user_user_connections( friends_data , @identity)
    
    Rails.logger.info "INFO Writing Twitter Followers Data"
    ConnectionHandler.build_user_user_connections( followers_data , @identity)
  end
  
  
  # Sends request to twitter for list of followers/friends
  # On callback we dispatch batch requests to the Twitter API
  def batch_connections
    @countdown = ConnectionHandler.countdown(2)
    
    Rails.logger.info "INFO Starting EventMachine"
    EventMachine.run do
      
      followers_req = EventMachine::HttpRequest.new(@twitter_url + '/1.1/followers/ids.json')
      followers_req.use EventMachine::Middleware::OAuth, @oauth_config
      
      friends_req = EventMachine::HttpRequest.new(@twitter_url + '/1.1/friends/ids.json')
      friends_req.use EventMachine::Middleware::OAuth, @oauth_config
      friends = friends_req.get
      
      friends.callback do
        raise "Failed to get friends ids " unless friends.response_header.status ==200
        @friend_ids = MultiJson.load( friends.response )['ids']
        connection_type = TwitterFriendship
        @old_friends, @new_friends = split_persisted(@friend_ids,  connection_type )
        Rails.logger.debug "DJ_TWITTER Friends: #{@friend_ids.length} New: #{@new_friends.length} Old:#{@old_friends.length}"
        @countdown.add( (@new_friends.length / @twitter_batch_size.to_f ).ceil.to_i )
        @friend_ids.each_slice( @twitter_batch_size ).map{  |batch| dispatch_friends(batch) } 
        stop_if_finished
      end

      followers = followers_req.get
      followers.callback do 
        raise "Failed to get follower ids " unless followers.response_header.status ==200
        @follower_ids = MultiJson.load( followers.response  )['ids']
        connection_type = TwitterFollowership
        @old_followers, @new_followers = split_persisted(@follower_ids, connection_type) 
        Rails.logger.debug "DJ_TWITTER Friends: #{@follower_ids.length} New: #{@new_followers.length} Old:#{@old_followers.length}"
        @countdown.add ( ( @new_followers.length / @twitter_batch_size.to_f ) .ceil.to_i )
        @follower_ids.each_slice(@twitter_batch_size).map{ |batch|  dispatch_followers(batch) }
        stop_if_finished 
      end

      friends.errback do
        Rails.logger.fatal "FATAL Failed to Retrieve Twitter Friends List"
        stop_if_finished
      end

      followers.errback do
        Rails.logger.fatal "FATAL Failed to Retrieve Twitter Follower List"
        stop_if_finished
      end
      
    end
    Rails.logger.info "INFO Stopping EventMachine"
  end

  # Constant for helping to build a Twitter ConnectionContext Info
  TwitterContext = {  :name => 'twitter-followership' } 
 
  TwitterFriendship = { :from => 'me', :to => 'you', :properties => {} }

  TwitterFollowership = { :from => 'you', :to => 'me', :properties => {} }

  # dispatch a batch function to twitter with OAuth1.0 Authorization
  # On Callback creates TpSubidenity info hashes and adds that to the friends buffer
  # On Error will retry 3 times before giving up
  def dispatch_friends( ids , tries = 0 )
    
    request = EM::HttpRequest.new( @twitter_url+'/1.1/users/lookup.json?user_id='+ ids.join(',') )
    request.use EM::Middleware::OAuth, @oauth_config 
    
    http = request.get
    http.callback do
      if http.response_header.status !=200
        Rails.logger.fatal "FATAL Twitter Friends Request Failed #{http.response_header.status}"
        Rails.logger.ap http
        raise "Twitter Bad Response Code"
      end
      
      
      begin
        friend_info = MultiJson.load( http.response)
        friends_batch  = friend_info.map{|friend| {
            :identity => {
              :uid => friend['id'],
              :context_name => 'twitter',
              :credentials => {},
              :name => "@" + friend['screen_name'],
              :url => "http://www.twitter.com/#{friend['screen_name']}",
              :image => self.class.process_image( friend['profile_image_url_https'] ) ,
              :properties => {}
            } ,
            :email => nil,
            :connection => TwitterFriendship
          }
         }
        @friends_buffer.concat friends_batch
        Rails.logger.info "INFO Twitter Friend Dispatch Success Countdown: #{@countdown.count}"
      rescue Exception => ex
        Rails.logger.fatal "FATAL : Failed to Parse Twitter Friend Response"
        Rails.logger.fatal "FATAL : Twitter Parse Error #{ex.message}"
        Rails.logger.fatal "FATAL : Twitter Parse Error Backtrace ... "
        ex.backtrace[0..10].each{ |trace| Rails.logger.fatal trace} 
        Rails.logger.ap http.response
      ensure
        stop_if_finished
      end
    end
    
    http.errback  do
      if tries <= 3
        Rails.logger.debug "DEBUG Friends Dispatch Failed Trying Again"
        dispatch_friends( ids, tries + 1 )
      else
        Rails.logger.fatal "FATAL Friends Dispath Failed Giving Up"
        stop_if_finished
      end
    end

  end
  
  # dispatch a batch function to twitter with OAuth1.0 Authorization
  # On Callback creates TpSubidenity info hashes and adds that to the followers buffer
  # On Error will retry 3 times before giving up
  def dispatch_followers ( ids,  tries = 0  )
    request = EM::HttpRequest.new( @twitter_url + '/1.1/users/lookup.json?user_id='+ids.join(',') )

    request.use EM::Middleware::OAuth, @oauth_config 
  
    http =  request.get
    http.callback do
      if http.response_header.status!=200
        Rails.logger.fatal "FATAL Twitter Follower Dispatch #{http.response_header.status}"
        Rails.logger.ap http
        raise "Bad Response Code"
      end 
      
      begin
        followers_info = MultiJson.load( http.response)
        followers_batch  = followers_info.map{ |follower| {
            :identity => {
              :uid => follower['id'],
              :context_name => 'twitter',
              :credentials => {},
              :name => "@" + follower['screen_name'],
              :url => "http://www.twitter.com/#{follower['screen_name']}",
              :image => self.class.process_image(follower['profile_image_url_https']),
              :properties => {}
             },
            :email => nil,
            :connection => TwitterFollowership
          }
         }
        @followers_buffer.concat followers_batch
        
        Rails.logger.info "INFO Twitter Follower Dispatch Successful - Countdown: #{@countdown.count}"
      rescue Exception => ex
        Rails.logger.fatal "FATAL Failed to Parse Twitter Followers Response"
        Rails.logger.fatal "FATAL : Twitter Parse Error #{ex.message}"
        Rails.logger.fatal "FATAL : Twitter Parse Error Backtrace ... "
        ex.backtrace[0..10].each{ |trace| Rails.logger.fatal trace} 
        Rails.logger.ap http.response 
        Rails.logger.fatal "FATAL Continuing Silently After Error"
      ensure
        stop_if_finished
      end
    end

    http.errback do
      if tries <= 3
        Rails.logger.debug "DEBUG Follower Dispatch Failed Trying Again"
        dispatch_followers( ids, tries + 1 )
      else
        stop_if_finished
        Rails.logger.fatal "FATAL Follower Dispath Failed Giving Up, Continuing Silently"
      end
    end
  end

  
  def self.process_image( image_url )
    begin
    if !image_url.nil?
      extension = image_url.split('.').last
      if    image_url.end_with?('_bigger.'+extension)
        offset = -1*('_bigger.'+extension).length
        size = '_bigger'.length
        image_url[offset,size]=""
      elsif image_url.end_with?('_normal.'+extension)
        offset = -1*('_normal.'+extension).length
        size = '_normal'.length
        image_url[offset,size]=""
      end
    end
    rescue 
      Rails.logger.fatal "FATAL Image URL Processing Error #{$!}"
      Rails.logger.fatal "FATAL Image URL Processing Error #{$@}"
    ensure
      return image_url
    end
  end

  # Decrements the countdown and turns off the EM Reactor if possible
  def stop_if_finished
    EM.stop if @countdown.minus_one == 0
  end

  def split_persisted( ids , connection_type) 
      queries = ids.map{|id| {:context_name => @context_name,:uid =>id}}
      
      persisted_id = Identity.batch_exists(queries)
      new_ids = ids.zip(persisted_id)                      \
                   .select{|id,persisted| not persisted }  \
                   .map{|id,persisted| id }
      
      old_ids = queries.zip(persisted_id)                  \
                   .select{|query,persisted| persisted}    \
                   .map{|query,persisted| {
                      :identity =>  query, 
                      :connection => connection_type
                     }
                    }
      [old_ids, new_ids]
  end

end
