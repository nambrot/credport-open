class EbayAPI

  def initialize( credentials, usertp )
    @username = usertp.uid
    @anonymous_image = Application.find_by_name('ebay').entity.image
    @credentials = usertp.credentials
    @usertp= usertp
  end

  def get_connections
    raw_data = get_user_feedback
    reviews = extract_reviews( raw_data )
    #stats = extract_stats( raw_data )
    
    if not Rails.env.production?
      File.open('tmp/ebay_reviews.json', 'w'){|f| f.write( reviews.to_json  )}
    end

    Rails.logger.debug "Ebay Reviews for #{@username}"
    Rails.logger.ap reviews 
    
    reviews.each do |review| 
      ConnectionHandler.build_user_user_connections( review , @usertp )
    end
  end

  def extract_reviews( data )
    return [] if data["User"].nil? or data["FeedbackHistory"].nil? or data['FeedbackDetails'].nil?

    details = data['FeedbackDetails'].keep_if{|review|!review["CommentText"].nil? }.map do |review|  
       {
         :context => {
           :name => get_context_name(review)
          },
         :connections => [{
         :identity => get_identity(review),
         :email => nil,
         :connection => {
         :from => 'you',
         :to => 'me',
         :properties=> {
         :text => review['CommentText'],
         :id => review['FeedbackID']
            }
          }
         }]
       }
     end
  end
  
  def get_identity(review)
    if review["CommentingUser"].nil?
       { :uid=> "anonymous-ebay-user-credport",:context_name=>"ebay"}
    else
       {
        :uid => review["CommentingUser"], 
        :context_name=> "ebay",
        :image => @anonymous_image,
        :credentials => {},
        :name => review["CommentingUser"],
        :url => "http://feedback.ebay.com/ws/eBayISAPI.dll?ViewFeedback2&userid=#{review["CommentingUser"]}&ftab=FeedbackAsBuyer",
        :subtitle => "Ebay User",
        :properties => {}
        }
    end
  end


  def get_context_name( review )
    case review["Role"]
      when "Buyer"
        return 'ebayfeedback-buyer'  
      when "Seller"
        return 'ebayfeedback-seller'
      else
        raise "Unexpected Feedback Role #{review["Role"]}"
    end
  end

  def get_user_feedback
    info = {:UserID => @username, :IncludeSelector => "FeedbackDetails,FeedbackHistory" }
    
    response = open_api( X_EBAY_API_GETUSERPROFILE_CALL_NAME, info )
    parsed_response = MultiJson.load( response )
    return parsed_response
  end

  def open_api( call_name, extra_parameters )
    params = open_ebay_request_params( call_name ).merge(extra_parameters)
    result =  HTTParty.get( OPEN_EBAY_URL , :query=>params ).body
  end

  def open_ebay_request_params( call_name )
    {
      :callname => call_name,
      :responseencoding => EBAY_RESPONSE_ENCODING_JSON ,
      :appid => Rails.configuration.api_keys['ebay']['appid'],
      :siteid => Rails.configuration.api_keys['ebay']['siteid'],
      :version => X_EBAY_API_COMPATIBILITY_LEVEL,
    }
  end
  
  X_EBAY_API_COMPATIBILITY_LEVEL = '675'
  EBAY_RESPONSE_ENCODING_JSON = "JSON"
  X_EBAY_API_GETUSERPROFILE_CALL_NAME = "GetUserProfile"
  OPEN_EBAY_URL = "http://open.api.ebay.com/shopping"
end
