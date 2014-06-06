require 'omniauth/strategies/oauth'

module OmniAuth
  module Strategies
    class Xing < OmniAuth::Strategies::OAuth

      args [:consumer_key, :consumer_secret]

      option :client_options, {
        :access_token_path  => '/v1/access_token',
        :authorize_path     => '/v1/authorize',
        :request_token_path => '/v1/request_token',
        :site               => 'https://api.xing.com',
      }

      info do
        {
          :first_name   => raw_info["first_name"],
          :last_name    => raw_info["last_name"],
          :email        => raw_info["active_email"],
          :image        => raw_info["photo_urls"]["large"],
          :url          => raw_info["permalink"],
        }
      end

      uid { access_token.params[:user_id] }

      extra do
        { 
          'raw_info' => raw_info,
          'credport' => {
            'identity' => {
              'uid' => access_token.params[:user_id],
              'context_name' => 'xing',
              'credentials' => credentials,
              'url' => raw_info["permalink"],
              'image' => raw_info['photo_urls']['large'],
              'name' => raw_info['first_name'] + ' ' + raw_info['last_name'],
              'subtitle' => get_tagline(raw_info),
              'properties' => {
                'total_contacts' => get_connection_count
              }
            },
            'email' => raw_info['active_email']
          }
        }
      end

      def raw_info
        @raw_info ||= MultiJson.decode( access_token.get('/v1/users/me').body )["users"].first
      end

      def get_connection_count
        @contact_count ||= MultiJson.decode( access_token.get("/v1/users/me/contacts?limit=0").body )["contacts"]["total"]
      end

      def get_tagline(raw_info)
        if raw_info.has_key?('professional_experience')
          if raw_info['professional_experience'].has_key?('primary_company')
            return "#{raw_info['professional_experience']['primary_company']['title']} at #{raw_info['professional_experience']['primary_company']['name']}"
          end
        end
        return ''
      end
      
    end
  end
end
