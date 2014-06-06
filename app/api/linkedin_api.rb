require 'em-http/middleware/oauth'

# Linkedin API with EventMachine
class LinkedinAPI
  
  # Builds a linkedin api from credentials and identity object
  def initialize( credentials, identity = nil )
    @linkedin_image_url = Application.find_by_name('linkedin').entity.image
    Rails.logger.debug "Linkedin Image Url = #{@linkedin_image_url}"
    @credentials = credentials 
    @linkedin_url  = 'https://api.linkedin.com'
    @linkedin_batch_size = 100
    @token = credentials[:token]
    @secret = credentials[:secret]
    @identity = identity
    @oauth_config  = {
        :consumer_key => Rails.configuration.api_keys['linkedin']['consumer_key'],
        :consumer_secret => Rails.configuration.api_keys['linkedin']['consumer_secret'],
        :access_token => @token,
        :access_token_secret => @secret
       }
  end
  
  # Gets Connection information Writes it to the DB
  def get_connections
   
    @connections_buffer = []
    @recommendations_buffer  = []
    @recommender_identity = {}
    @countdown =  ConnectionHandler.countdown(2) # Currently only making exactly 2 calls

    EventMachine.run do
      dispatch_connections
      dispatch_recommendations
    end
    connection_data = { :context => LinkedinContext , :connections => @connections_buffer  }

    # Look up the identity hash for the associated recommender
    @recommendations_buffer.each do |recommendation_hash|
      identity = @recommender_identity[recommendation_hash[:connections].first[:identity][:uid]]
      identity ||= { :uid => 'anonymous-linkedin-user-credport', :context_name => 'linkedin' }
      recommendation_hash[:connections].first[:identity].merge!(identity)
    end

    @exception_data = [connection_data,@recommendation_buffer]
    if Rails.env != 'production'
      Rails.logger.debug "DEBUG:  Wrote the Linkedin connection/recommendation data to tmp"
      File.open( 'tmp/linkedin_friends.json' , 'w'){ |f| f.write(connection_data.to_json) }
      File.open( 'tmp/linkedin_credentials.json' , 'w'){ |f| f.write( @credentials.to_json ) }
      File.open( 'tmp/linkedin_recommendations.json', 'w'){ |f|  f.write( @recommendations_buffer.to_json)}
    end
    
    raise "No User Tpsubidentity set" if @identity.nil?
    ConnectionHandler.build_user_user_connections( connection_data , @identity)
    @recommendations_buffer.each do |recommendation_hash|
      ConnectionHandler.build_user_user_connections( recommendation_hash , @identity)
    end

  end

  # Returns the workplaces making async calls
  #
  # * *Args*
  #  - positions :  An array of company hashes from linkedin raw_info api response
  #
  # * *Returns*
  #   - workplace_info : an array of the same length with hybrid hashes of workplace and position information
  def get_attributes( positions )
    positions.keep_if {|position| position[:company].has_key? :id }
    positions.map!{ |position| position.deep_symbolize_keys}
    @workplaces_buffer = Hash.new()
    
    # Extract the unique ids
    ids = positions.map{ |position| position[:company][:id] }.uniq.compact

    @countdown =  ConnectionHandler.countdown(ids.length )
    
    # Make async calls
    if ids.length > 0
      EventMachine.run do
         ids.each{ |id| dispatch_workplaces(id) }
      end
    end

    workplaces_info = positions.map do |item| 
      item[:company].merge!(@workplaces_buffer[item[:company][:id]])
      item
    end

    if Rails.env != 'production'
      File.open( 'tmp/linkedin_workplaces.json' , 'w'){ |f| f.write(workplaces_info.to_json)}
    end
    
    work_hash = {
            :workplaces => workplaces_info.map{ |position| {
            :workplace => {
              :uid => position[:company][:name],
              :context_name => 'credport_workplace_context',
              :name => position[:company][:name],
              :image => position[:company].has_key?(:logoUrl) ? self.class.process_image(position[:company][:logoUrl]) : WorkAttribute.anonymous_workplace.image,
              :url => self.class.extract_url(position[:company]) ,
              :properties => {
                :description => position[:company].has_key?(:description) ? position[:company][:description] : "",
                :industry => position[:company].has_key?(:industry) ? position[:company][:industry] : ""
              }

            },
            :title => position[:title],
            :summary => position.has_key?(:summary) ? position[:summary] : "",
            :from => self.class.transform_date(position[:startDate]),
            :to => self.class.transform_date(position[:endDate]) ,
            :current => position.has_key?(:endDate) ? false : true
          }}}
  end

  # Dispatchs Asyncronous HTTP calls to LinkedinAPI one for every company.
  def dispatch_workplaces( id )
    request = EventMachine::HttpRequest.new(@linkedin_url + "/v1/companies/#{id}" +":(#{WorkplaceFields.join(',')})?format=json") 
    request.use EventMachine::Middleware::OAuth, @oauth_config

    http = request.get
    http.callback do
      debugger
      if http.response_header.status != 200
        Rails.logger.fatal "Linkedin Workplace Lookup Unexpected Response Code"\
                           "#{http.response_header.status}"
        Rails.logger.ap  http
        @workplaces_buffer[id] = {} 
      end

      begin 
        data = MultiJson.load( http.response ).deep_symbolize_keys
        @workplaces_buffer[id]  = data
        Rails.logger.info "Linkedin Workplaces Dispatch Successful - Countdown: #{@countdown.count}"
      rescue Exception => ex
        Rails.logger.fatal "FATAL : Linekdin Parse Error #{ex.message}"
        Rails.logger.fatal "FATAL : Linkedin Parse Error Backtrace ... "
        ex.backtrace[0..10].each{ |trace| Rails.logger.fatal trace} 
        Rails.logger.fatal "Error Reading the response#{@countdown.count}"  
        Rails.logger.ap http.response
      ensure
        stop_if_finished 
      end
    end

    http.errback do
      if tries <= 3
        Rails.logger.warn "Linkedin Workplace Request Failed #{@countdown.count}, Trying again"
        dispatch_connections( id , tries + 1 )
      else
        Rails.logger.warn "Linkedin Workplace Request Failed #{@countdown.count}, Giving Up"
        stop_if_finished
      end
    end
      
  end

  def dispatch_connections( tries = 0 )
    request = EventMachine::HttpRequest.new(@linkedin_url + '/v1/people/~/connections?format=json&count=0&start=0')
    request.use EventMachine::Middleware::OAuth, @oauth_config
    http = request.get 

    http.callback do
        if http.response_header.status != 200
          Rails.logger.fatal "Linkedin ConnectionInfo Request Failed with Error Code #{http.response_header.status}"
          Rails.logger.ap http
          raise "Unexpect response status #{http}" unless http.response_header.status == 200
        end
        
        begin
          data = MultiJson.decode(http.response)
          raise "No _total key found in response" unless data["_total"]
          
          total = data["_total"]
          start = 0
          count = @linkedin_batch_size
          
          while start < total
             Rails.logger.debug "Linkedin Fetch Start: #{start} , Count: #{count}, Total: #{total}"
             @countdown.add(1)
             fetch_connection( start, count )
             start += count
          end

        rescue Exception => ex
          Rails.logger.fatal "FATAL : Linekdin ConnectionInfo Parse Error #{ex.message}"
          Rails.logger.fatal "FATAL : Linkedin ConnectionInfo Parse Error Backtrace ... "
          ex.backtrace[0..10].each{ |trace| Rails.logger.fatal trace} 
          Rails.logger.fatal "Linkedin ConnectionInfo Dispatch Bad Response #{@countdown.count}"
          Rails.logger.ap http.response
        ensure
          stop_if_finished
        end
    end

    http.errback do
        if tries <= 3
          Rails.logger.warn "Linkedin Fetch Connection Info Request #{ @countdown.count}, Trying again"
          dispatch_connections( tries + 1 )
        else
          Rails.logger.fatal "Linkedin Fetch Connection Info Request #{ @countdown.count}, Giving Up"
          stop_if_finished
         end
     end

  end

  # Makes single Linkedin Connection call for 500 connections - ignore remainder at the moment
  # On Call back creates hashs for building tpsubidentites and stores in the connections buffer
  # On error tries 3 times before giving up
  def fetch_connection( start=0 , count=500 , tries = 0 )
      request = EventMachine::HttpRequest.new(@linkedin_url + "/v1/people/~/connections?format=json&count=#{count}&start=#{start}")
      request.use EventMachine::Middleware::OAuth, @oauth_config
      http = request.get 
      
      http.callback do
        if http.response_header.status != 200
          Rails.logger.fatal "Linkedin Connection Request Failed with Error Code #{http.response_header.status}"
          Rails.logger.ap http
          raise "Unexpect response status #{http}" unless http.response_header.status == 200
        end
        
        begin
          data = MultiJson.decode(http.response)['values']
          connection_info = data.map{|data| data.deep_symbolize_keys }.keep_if{ |connection| connection.has_key?(:pictureUrl) }.map{ |connection| 
                  {
                  :identity => {
                    :uid => connection[:id],
                    :context_name => :linkedin,
                    :credentials => {},
                    :name => connection[:firstName] + ' '+ connection[:lastName],
                    :image => self.class.process_image(connection[:pictureUrl]),
                    :url => connection[:siteStandardProfileRequest][:url],
                    :properties => {
                      'Headline' => connection[:headline]
                    }
                  },
                  :email => nil,
                  :connection => {
                    :from => 'me',
                    :to => 'you',
                    :properties => {}
                  }
                }
          }
          @connections_buffer.concat( connection_info)
          Rails.logger.info "Linkedin Connections Dispath Successful Countdown: #{@countdown.count}"
        rescue Exception => ex
          Rails.logger.fatal "FATAL : Linekdin Parse Error #{ex.message}"
          Rails.logger.fatal "FATAL : Linkedin Parse Error Backtrace ... "
          ex.backtrace[0..10].each{ |trace| Rails.logger.fatal trace} 
          Rails.logger.fatal "Linkedin Connection Dispatch Bad Response #{@countdown.count}"
          Rails.logger.ap http.response
        ensure
          stop_if_finished
        end
      end

      http.errback do
        if tries <= 3
          Rails.logger.warn "Linkedin Connection Request #{ @countdown.count}, Trying again"
          fetch_connection( start , count , tries + 1 )
        else
          Rails.logger.fatal "Linkedin Connection Request #{ @countdown.count}, Giving Up"
          stop_if_finished
        end
      end
  end

  def dispatch_recommendations( tries = 0 )
      request = EventMachine::HttpRequest.new(@linkedin_url+'/v1/people/~:(recommendations-received)?format=json')
      request.use EventMachine::Middleware::OAuth, @oauth_config
      http = request.get 

      http.callback do
        
        if http.response_header.status != 200
          Rails.logger.fatal "Linkedin Recommendation Request Failed: Error Code #{http.response_header.status}"
          Rails.logger.ap http
          raise "Unexpect response status #{http}" unless http.response_header.status == 200
        end
        
        begin
          data = MultiJson.decode(http.response)
          if data['recommendationsReceived'] && data['recommendationsReceived']['values']
            data = data['recommendationsReceived']['values']
            data.map!{|data| data.deep_symbolize_keys }.map! do |recommendation| 
              get_recommender( recommendation[:recommender]);
                {
                  :context => {
                    :name => getContextNameFromRecommendation(recommendation)
                  },
                  :connections => [{
                    :identity => { :uid => recommendation[:recommender][:id] },
                    :email => nil,
                    :connection => {
                      :from => 'you',
                      :to => 'me',
                      :properties => {
                        :text => recommendation[:recommendationText],
                        :id => recommendation[:id]
                      }
                    }
                    }]
                }
              end
            @recommendations_buffer.concat( data  )
          else
            Rails.logger.info "Linkedin Recommendation : No Recommendations to Write"
          end
          Rails.logger.info "Linkedin Recommendations Dispath Successful Countdown: #{@countdown.count}"
        rescue Exception => ex
          Rails.logger.fatal "FATAL : Linekdin Parse Error #{ex.message}"
          Rails.logger.fatal "FATAL : Linkedin Parse Error Backtrace ... "
          ex.backtrace[0..10].each{ |trace| Rails.logger.fatal trace} 
          Rails.logger.fatal "Linkedin Recommendations Dispatch Unparsable Response #{@countdown.count}"
          Rails.logger.ap http.response
        ensure
          stop_if_finished
        end
      end

      http.errback do
        if tries <= 3
          Rails.logger.warn "Linkedin Recommendation Request Erred #{ @countdown.count}, Trying again"
          dispatch_connections( tries + 1 )
        else
          Rails.logger.fatal "Linkedin Recommendation Request Failed #{ @countdown.count}, Giving up"
          Rails.logger.ap http
          stop_if_finished
        end
      end
  end

  def dispatch_recommender( uid , tries = 0)
      request = EventMachine::HttpRequest.new(@linkedin_url+"/v1/people/id=#{uid}"+ 
        ":(first-name,last-name,public-profile-url,picture-url,headline,site-standard-profile-request)?format=json")
      request.use EventMachine::Middleware::OAuth, @oauth_config
      http = request.get 

      http.callback do
        if http.response_header.status != 200
          Rails.logger.fatal "Linkedin Recommender Request Failed: Error Code #{http.response_header.status}"
          Rails.logger.ap http
          raise "Unexpect response status #{http}" unless http.response_header.status == 200
        end
        
        identity = nil 
        begin
          connection = MultiJson.decode(http.response).deep_symbolize_keys
          identity = {
                    :uid => uid,
                    :context_name => 'linkedin',
                    :credentials => {},
                    :name => connection[:firstName] + ' ' + connection[:lastName],
                    :image => connection[:pictureUrl].nil? ? @linkedin_image_url : self.class.process_image(connection[:pictureUrl]),
                    :url => connection[:siteStandardProfileRequest][:url],
                    :properties => {
                      'Headline' => connection[:headline]
                    }
          }
          Rails.logger.info "Linkedin Recommender Dispath Successful Countdown: #{@countdown.count}"
          Rails.logger.ap identity
        rescue Exception => ex
          Rails.logger.fatal "FATAL : Linekdin Parse Error #{ex.message}"
          Rails.logger.fatal "FATAL : Linkedin Parse Error Backtrace ... "
          ex.backtrace[0..10].each{ |trace| Rails.logger.fatal trace} 
          Rails.logger.fatal "Linkedin Recommender Dispatch Unparsable Response #{@countdown.count}"
          Rails.logger.ap http.response
        ensure
          @recommender_identity[uid]= identity
          stop_if_finished
        end
      end

      http.errback do
        if tries <= 3
          Rails.logger.warn "Linkedin Recommender Request Erred #{ @countdown.count}, Trying again"
          dispatch_connections( uid, tries + 1 )
        else
          Rails.logger.fatal "Linkedin Recommender Request Failed #{ @countdown.count}, Giving up"
          Rails.logger.ap http
          stop_if_finished
        end
      end
  end
  
  def self.process_image( image_url)
    if !image_url.nil? and ( image_url.start_with?('http://') ) 
      pieces = image_url.split('.')
      pieces[0]+='-s'
      image_url = pieces.join('.')
      image_url[0,('http://'.size)]="https://"
    end
    image_url
  end

  # Looks up one recommender at a time
  # Make an async request 
  def get_recommender( recommender  )
    if  ( !(recommender[:id]=="private") and 
          !(recommender[:firstName]=="private") and 
          !(recommender[:lastName]=="private") ) 
             Rails.logger.debug "DEBUG Recommender Info Availabling, making dispatch"
             @countdown.add(1)
             dispatch_recommender( recommender[:id])
    end
  end

  def getContextNameFromRecommendation(recommendation)
    case recommendation[:recommendationType][:code]
    when 'education'
      return 'linkedinrecommendation-education'
    when 'colleague'
      return 'linkedinrecommendation-colleague'
    when 'business-partner'
      return 'linkedinrecommendation-bp'
    when 'service-provider'
      return 'linkedinrecommendation-sp'
    end
  end
  
  # Linkedin connection Constant
  LinkedinContext = { :name => 'linkedin-connection' }

  WorkplaceFields =  ["name","universal-name","website-url","logo-url","description"]
  
  # Decrements countdown object and stops the EM Reactor if calls are finished
  def stop_if_finished
    EM.stop if @countdown.minus_one == 0
  end

  def self.search_url(name)
     "http://www.google.com/search?q=#{URI.escape(name)}"
  end

  def self.extract_url(company)
    
    if company.has_key?(:websiteUrl)
      site = company[:websiteUrl]
      if uri?(site)
        return site
      else
        return search_url(company[:name])
      end
    else
      return search_url(company[:name])
    end
  end

  def self.transform_date( date_hash )
    date = {}
    if  not ( date_hash.nil? or (date_hash[:month].nil? and date_hash[:year].nil?) )
      date[:month] = date_hash[:month].nil? ? "00" : date_hash[:month].to_s 
      date[:year] = date_hash[:year].nil? ? "00" : date_hash[:year].to_s 
    end
    date
  end

  def self.uri?( string )
    uri = URI.parse(string)
    %w( http https ).include?(uri.scheme)
  rescue URI::BadURIError
    false
  rescue URI::InvalidURIError
    false
  end

end

