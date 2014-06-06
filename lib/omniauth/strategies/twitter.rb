require 'omniauth-oauth'
require 'multi_json'

module OmniAuth
  module Strategies
    class Twitter < OmniAuth::Strategies::OAuth
      option :name, 'twitter'
      option :client_options, {:authorize_path => '/oauth/authenticate',
                               :site => 'https://api.twitter.com'}

      uid { access_token.params[:user_id] }

      info do
        {
          :nickname => raw_info['screen_name'],
          :name => raw_info['name'],
          :location => raw_info['location'],
          :image => TwitterAPI.process_image(raw_info['profile_image_url_https']),
          :description => raw_info['description'],
          :urls => {
            'Website' => raw_info['url'],
            'Twitter' => 'http://twitter.com/' + raw_info['screen_name'],
          }
        }
      end

      extra do
          ap raw_info
          ap TwitterAPI.process_image(raw_info['profile_image_url_https'])
        { 
          :tagline => raw_info['description'],
          :raw_info => raw_info,
          :credport => {
            :identity => {
              'uid' => raw_info['id'],
              'context_name' => 'twitter',
              'credentials' => {
                'token' => access_token.token,
                'secret' => access_token.secret
              },
              'name' => "@" + raw_info['screen_name'],
              'url' => "http://www.twitter.com/#{raw_info['screen_name']}",
              'image' => TwitterAPI.process_image(raw_info['profile_image_url_https']),
              'subtitle' => "#{raw_info['followers_count']} Followers",
              'properties' => {
                'Followers' => raw_info['followers_count'],
                'Following' => raw_info['friends_count'],
                'Location' => raw_info['location'],
                'Tweets' => raw_info['statuses_count'],
                'Description' => raw_info['description'] 
              }
            },
            :email => nil,
            }
          } 
      end
     

      # DEPRICATED
      def friendships
        friendshipids = MultiJson.load(access_token.get('/1.1/friends/ids.json').body)
        MultiJson.load(access_token.get('/1.1/users/lookup.json?user_id=' + friendshipids['ids'][1..99].to_json).body)
      end
     
      # DEPRECATED
      def followers
        followerids = MultiJson.load(access_token.get('/1.1/followers/ids.json').body)
        MultiJson.load(access_token.get('/1.1/users/lookup.json?user_id=' + followerids['ids'][1..99].to_json).body)
      end
      
        
      def raw_info
        @raw_info ||= MultiJson.load(access_token.get('/1.1/account/verify_credentials.json').body)
      rescue ::Errno::ETIMEDOUT
        Rails.logger.fatal "OAuth Twitter Raw Info Call Failed"
        raise ::Timeout::Error
      end

      alias :old_request_phase :request_phase

      def request_phase
        screen_name = session['omniauth.params'] ? session['omniauth.params']['screen_name'] : nil
        x_auth_access_type = session['omniauth.params'] ? session['omniauth.params']['x_auth_access_type'] : nil
        if screen_name && !screen_name.empty?
          options[:authorize_params] ||= {}
          options[:authorize_params].merge!(:force_login => 'true', :screen_name => screen_name)
        end
        if x_auth_access_type
          options[:request_params] || {}
          options[:request_params].merge!(:x_auth_access_type => x_auth_access_type)
        end
        old_request_phase
      end

    end
  end
end
