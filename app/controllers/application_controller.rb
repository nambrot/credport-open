class ApplicationController < ActionController::Base
  include ApplicationHelper
  protect_from_forgery
    
  before_filter :set_locale
   
  def set_locale
    session[:locale] = params[:tlocale] unless session[:locale]
    session[:locale] = params[:locale] if params[:locale]
    I18n.locale = session[:locale] || I18n.default_locale
  end
 
end
