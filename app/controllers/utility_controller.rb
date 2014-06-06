class UtilityController < ApplicationController
before_filter :authenticate_user!, :only => [:getverifieds]
respond_to :json, :xml

	def country
    response = HTTParty.get "http://www.webservicex.net/geoipservice.asmx/GetGeoIP?IPAddress=#{request.remote_ip}"
    country = response["GeoIP"]["CountryName"]
    respond_with({
          :country => country
        })
  end

  def verifieds 
    @emails = current_user.emails_to_verify
    @phones = current_user.phones_to_verify
    @websites = current_user.websites_to_verify
  end

  def csrf
    render :js => <<-eos
$("meta[name='csrf-param']").attr('content', '#{Rack::Utils.escape_html(request_forgery_protection_token)}');
$("meta[name='csrf-token']").attr('content', '#{Rack::Utils.escape_html(form_authenticity_token)}');
    eos

  end

  def setLocale
    session[:locale] = params[:locale] if params[:locale]
    render :text => (params[:locale] ? '1' : '0')
  end
end
