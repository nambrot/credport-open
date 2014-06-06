require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class PayPal < OmniAuth::Strategies::OAuth2
      DEFAULT_SCOPE = "openid profile"
      DEFAULT_RESPONSE_TYPE = "code"

      option :client_options, {
        :site          => 'https://www.paypal.com',
        :authorize_url => '/webapps/auth/protocol/openidconnect/v1/authorize',
        :token_url     => '/webapps/auth/protocol/openidconnect/v1/tokenservice',
      }

      option :authorize_options, [:scope, :response_type]
      option :provider_ignores_state, true

      uid { @parsed_uid ||= (/\/([^\/]+)\z/.match raw_info['user_id'])[1] } #https://www.paypal.com/webapps/auth/identity/user/baCNqjGvIxzlbvDCSsfhN3IrQDtQtsVr79AwAjMxekw => baCNqjGvIxzlbvDCSsfhN3IrQDtQtsVr79AwAjMxekw
    
      info do
        {
          'name' => raw_info['fullName'],
          'first_name' => raw_info['firstName'],
          'last_name' => raw_info['lastName'],
          'email' => email(raw_info),
          'phone' => raw_info['telephoneNumber']
        }
      end

      extra do
        {
          'credport' => {
            'identity' => {
              'uid' => raw_info['user_id'],
              'context_name' => 'paypal',
              'credentials' => {
                'token' => access_token.token
              },
              'name' => raw_info['given_name'] + ' ' + raw_info['family_name'],
              'image' => "https://s3.amazonaws.com/credport-assets/assets/icon_paypal.png",
              "url" => 'http://www.paypal.com',
              'subtitle' => raw_info['verified_account'] ? "Verified Account" : "Standard Account" ,
              'properties' => {
              }
            },
            'email' => raw_info['email'],
            'phone' => raw_info['phone_number']
            
          },
          'raw_info' => raw_info,
          'emails' => raw_info['emails'],
          'addresses' => raw_info['addresses'],
          'status' => raw_info['status'],
          'language' =>  raw_info['language'],
          'dob' => raw_info['dob'],
          'timezone' => raw_info['timezone'],
          'payerID' => raw_info['payerID']
        }
      end

      def email(raw_info)
        if raw_info['emails'] && !raw_info['emails'].empty?
          raw_info['emails'][0]
        end
      end

      def raw_info
        @raw_info ||= load_identity()
      end

      def authorize_params
        super.tap do |params|
          params[:scope] ||= DEFAULT_SCOPE
          params[:response_type] ||= DEFAULT_RESPONSE_TYPE
        end
      end

      private
        def load_identity
          access_token.options[:mode] = :query
          access_token.options[:param_name] = :access_token
          access_token.options[:grant_type] = :authorization_code
          access_token.get('/webapps/auth/protocol/openidconnect/v1/userinfo', { :params => { :schema => 'openid'}}).parsed || {}
        end
    end
  end
end

OmniAuth.config.add_camelization 'paypal', 'PayPal'