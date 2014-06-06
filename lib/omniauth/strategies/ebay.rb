require 'omniauth'

module OmniAuth
  module Strategies
    class Ebay
      include OmniAuth::Strategy
      include EbayAuthHelper

      EBAY = 'ebay'

      args [:runame, :devid, :appid, :certid, :siteid, :apiurl]
      option :name, "ebay"
      option :runame, nil
      option :devid, nil
      option :appid, nil
      option :certid, nil
      option :siteid, nil
      option :apiurl, nil

      uid { raw_info['UserID'] }
      info do
        {
            :ebay_id => raw_info['UserID'],
            :ebay_token => @auth_token,
            :email => raw_info['Email'],
            :full_name => raw_info["RegistrationAddress"] && raw_info["RegistrationAddress"]["Name"],
            :country => raw_info["RegistrationAddress"] && raw_info["RegistrationAddress"]["Country"]
        }
      end

      extra do
        {
            :internal_return_to => request.params['internal_return_to'] || request.params[:internal_return_to],
            :credport => {
              :identity =>{
                :uid => raw_info['UserID'],
                :context_name => EBAY ,
                :credentials => {:token => @auth_token, :eias_token => raw_info["EIASToken"]},
                :name => raw_info["RegistrationAddress"] && raw_info["RegistrationAddress"]["Name"],
                :image => Application.find_by_name('ebay').entity.image,
                :url => "http://feedback.ebay.com/ws/eBayISAPI.dll?ViewFeedback2&userid=#{raw_info["UserID"]}&ftab=FeedbackAsBuyer",
                :subtitle => get_subtitle,  
                :properties => {}
              },
            :email => raw_info['Email'], 
            :phone => raw_info["RegistrationAddress"] && raw_info["RegistrationAddress"]['Phone']
          },
          :name => raw_info["RegistrationAddress"] && raw_info["RegistrationAddress"]["Name"],
          :raw_info => raw_info
        }
      end

      #1: We'll get to the request_phase by accessing /auth/ebay
      #2: Request from eBay a SessionID
      #3: Redirect to eBay Login URL with the RUName and SessionID
      def request_phase
        session_id = generate_session_id
        redirect ebay_login_url(session_id)
      rescue => ex
        fail!("Failed to retrieve session id from ebay", ex)
      end

      #4: We'll get to the callback phase by setting our accept/reject URL in the ebay application settings(/auth/ebay/callback)
      #5: Request an eBay Auth Token with the returned username&secret_id parameters.
      #6: Request the user info from eBay
      def callback_phase
        @auth_token = get_auth_token(request.params["username"], request.params["sid"])
        @user_info = get_user_info(request.params["username"], @auth_token)
        ap @user_info
        super
      rescue => ex
        fail!("Failed to retrieve user info from ebay", ex)
      end

      def raw_info
        @user_info
      end

      def get_subtitle
        if raw_info["FeedbackPrivate"].eql?("false") 
          return "Feedback Score #{raw_info["FeedbackScore"]}"
        elsif raw_info["eBayGoodStanding"].eql?("true")
          return "Ebay User In Good Standing"
        else
          return "Ebay User"
        end
      end
    end
  end
end

OmniAuth.config.add_camelization 'ebay', 'Ebay'
