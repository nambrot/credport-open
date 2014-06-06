require 'omniauth/strategies/oauth'
module OmniAuth
  module Strategies
    class LinkedIn < OmniAuth::Strategies::OAuth
      option :name, "linkedin"

      option :client_options, {
        :site => 'https://api.linkedin.com',
        :request_token_path => '/uas/oauth/requestToken',
        :access_token_path => '/uas/oauth/accessToken',
        :authorize_url => 'https://www.linkedin.com/uas/oauth/authenticate'
      }
      option :fields, ["id", "first-name", "last-name", "headline", "industry", "picture-url", "public-profile-url", 'summary', 'specialties', 'interests','associations', 'honors', 'positions', 'publications', 'educations', 'recommendations-received']
      option :scope, 'r_basicprofile r_emailaddress'
      uid{ raw_info['id'] }

      info do
          {
          :first_name => raw_info['firstName'],
          :last_name => raw_info['lastName'],
          :name => "#{raw_info['firstName']} #{raw_info['lastName']}",
          :headline => raw_info['headline'],
          :image => LinkedinAPI.process_image(raw_info['pictureUrl']),
          :industry => raw_info['industry'],
          :urls => {
            'public_profile' => raw_info['publicProfileUrl']
          }}
      end


      extra do
       {
          :raw_info => raw_info,
          :tagline => raw_info['headline'],
          :name => raw_info['firstName'] + ' '+ raw_info['lastName'],
          :education => educations.map{ |education| {
            :school => {
              :uid => education['schoolName'],
              :context_name => 'linkedin',
              :name => education['schoolName'],
              :image => EducationAttribute.anonymous_school.image,  #Links to anonymous image ... 
              :url => LinkedinAPI.search_url(education['schoolName'])
            },
            :majors => education.has_key?('fieldOfStudy') ? [education['fieldOfStudy'] ] :  [],
            :station => 'college',
            :classyear => education.has_key?('endDate') ? education['endDate']['year'].to_s : "?"
          } },
          :credport => {
            'identity' => {
              'uid' => raw_info['id'],
              'context_name' => 'linkedin',
              'credentials' => {
                'token' => access_token.token,
                'secret' => access_token.secret
              },
              'subtitle' => raw_info['headline'],
              'name' => raw_info['firstName'] + ' ' + raw_info['lastName'],
              'image' => LinkedinAPI.process_image(raw_info['pictureUrl']),
              "url" => raw_info['publicProfileUrl'],
              'properties' => {
               
              }
            }
          }
        }
      end

      def educations
        (raw_info.has_key?('educations') and raw_info['educations'].has_key?('values')) ? raw_info['educations']['values'] : []
      end

      def request_phase
        options.request_params ||= {}
        options.request_params[:scope] = options.scope.gsub("+", " ")
        super
      end

      def raw_info
        if @raw_info.nil?
          x = Time.now().to_f
          @raw_info = MultiJson.decode(access_token.get("/v1/people/~:(#{options.fields.join(',')})?format=json").body)
          ap "RAWINFO "+(Time.now().to_f - x ).to_s
          Rails.logger.info "LinkedinAPI Raw info successful"
#         File.open( 'tmp/linkedin_raw_info.json'  ,'w'){ |f| f.write( @raw_info.to_json ) }
        end
        @raw_info

      end
    end
  end
end

OmniAuth.config.add_camelization 'linkedin', 'LinkedIn'

