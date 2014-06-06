require 'omniauth-twitter'
require 'omniauth-facebook'
require 'omniauth-linkedin'
require 'omniauth-ebay'
require 'omniauth-paypal'
require 'omniauth-xing'


Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, Rails.configuration.api_keys['facebook']['consumer_key'], Rails.configuration.api_keys['facebook']['consumer_secret'], :scope => 'email, user_likes, user_work_history, user_education_history, user_birthday, user_about_me'
  provider :twitter, Rails.configuration.api_keys['twitter']['consumer_key'], Rails.configuration.api_keys['twitter']['consumer_secret']
  provider :linkedin, Rails.configuration.api_keys['linkedin']['consumer_key'], Rails.configuration.api_keys['linkedin']['consumer_secret'], :scope => 'r_fullprofile+r_emailaddress+r_network'
 provider :ebay, Rails.configuration.api_keys['ebay']['runame'], Rails.configuration.api_keys['ebay']['devid'], Rails.configuration.api_keys['ebay']['appid'], Rails.configuration.api_keys['ebay']['certid'], Rails.configuration.api_keys['ebay']['siteid'], Rails.configuration.api_keys['ebay']['apiurl']
 provider :paypal, Rails.configuration.api_keys['paypal']['key'], Rails.configuration.api_keys['paypal']['token'], {:scope => "openid profile email phone https://uri.paypal.com/services/paypalattributes"}
 provider :xing, Rails.configuration.api_keys['xing']['key'], Rails.configuration.api_keys['xing']['secret']

end

