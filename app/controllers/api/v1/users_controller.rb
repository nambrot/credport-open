module Api::V1
  class UsersController < ApiController
    include Api::V1::UsersHelper
    respond_to :json, :xml, :html, :js
    before_filter :getuser
    caches_action :show, :cache_path => :show_cache_path.to_proc
    caches_action :verifications, :cache_path => :verifications_cache_path.to_proc
    caches_action :commonconnections, :cache_path => :commonconnections_cache_path.to_proc, :if => Proc.new{|x| x.callback_cache_condition }, :expires_in => 10.minutes
    caches_action :commoninterests, :cache_path => :commoninterests_cache_path.to_proc, :if => Proc.new{|x| x.callback_cache_condition }, :expires_in => 10.minutes
    caches_action :stats, :cache_path => :stats_cache_path.to_proc, :if => Proc.new{|x| x.callback_cache_condition }, :expires_in => 10.minutes

    skip_before_filter :verify_authenticity_token
    

    def commonconnections_cache_path
      prepare_pagination('/commonconnections')
      viewer = params.has_key?(:viewer) ? User.find_param(params[:viewer]) : current_user
      return "user-api-action-commonconnections-#{@user.nil? ? 0 : @user.cache_key}-#{viewer ? viewer.cache_key : 0}}-#{@current_page}-#{@per_page}-#{I18n.locale}"
    end

    def commoninterests_cache_path
      prepare_pagination('/commoninterests')
      viewer = params.has_key?(:viewer) ? User.find_param(params[:viewer]) : current_user
      return "user-api-action-commoninterests-#{@user.nil? ? 0 : @user.cache_key}-#{viewer ? viewer.cache_key : 0}}-#{@current_page}-#{@per_page}-#{I18n.locale}"
    end

    def stats_cache_path
      viewer = params.has_key?(:viewer) ? User.find_param(params[:viewer]) : current_user
      return "user-api-action-stats-#{@user.nil? ? 0 : @user.cache_key}-#{viewer ? viewer.cache_key : 0}-#{I18n.locale}"
    end

    def callback_cache_condition
      return !params.has_key?(:callback)
    end

    def show_cache_path
      return "user-api-show-#{@user.nil? ? 0 : @user.cache_key}-#{current_user ? current_user.id : 0}-#{params[:include]}-#{params[:callback]}-#{I18n.locale}"
    end

    def verifications_cache_path
      
      return "user-api-verifications-#{@user.nil? ? 0 : @user.cache_key}-#{current_user ? current_user.id : 0}}-#{params[:callback]}-#{I18n.locale}"
    end

    def show
      getuser

      @user.mixpanel_track("API::Users::Show", { :referrer => get_domain(request.referrer), :current_user => current_user.try(:to_param) })
      @user.mixpanel_increment({ "API::Users::Show" => 1, "API::Users::Show::#{get_domain(request.referrer)}" => 1})
      current_user.mixpanel_track("API::Users::View", { :referrer => get_domain(request.referrer), :view => @user.to_param }) if current_user
      current_user.mixpanel_increment({"Api::Users:View" => 1,"API::Users::View::#{get_domain(request.referrer)}" => 1 }) if current_user
      respond_with(@user) do |format|
        format.html {render 'users/show', :layout => false}
        format.any(:xml, :json) { render('users/show') }
      end
    end
    
    def work
      respond_with(@user) do |format|
        format.html {render 'users/show', :layout => false}
        format.any(:xml, :json) { render('users/work') }
      end
    end
    
    def education
      respond_with(@user) do |format|
        format.html {render 'users/show', :layout => false}
        format.any(:xml, :json) { render('users/education') }
      end
    end
    
    def verifications
      respond_with(@user) do |format|
        format.html {render 'users/show', :layout => false}
        format.any(:xml, :json) { render('users/verifications') }
      end
    end
    
    def identities
      respond_with(@user) do |format|
        format.html {render 'users/show', :layout => false}
        format.any(:xml, :json) { render('users/identities') }
      end
    end
    
    def commonconnections
      prepare_pagination("/commonconnections")
      viewer = params.has_key?(:viewer) ? User.find_param(params[:viewer]) : current_user
      if viewer.nil? or viewer == @user
        @paths = []
      else
        begintime = Time.now
          @paths = Rails.cache.fetch("api-common-connections-#{viewer.cache_key}-#{@user.cache_key}-#{@current_page}-#{@per_page}", :expires_in => 10.minutes){ Connection.common_connections(viewer, @user, @current_page, @per_page)}
          ap "sc #{Time.now - begintime}"
      end
      respond_with @paths do |format|
        format.html {render 'users/show', :layout => false}
        format.any(:xml, :json) { render('users/commonconnections') }
      end
    end
    
    def commoninterests
      prepare_pagination('/commoninterests')
      viewer = params.has_key?(:viewer) ? User.find_param(params[:viewer]) : current_user
      if viewer.nil? or viewer == @user
        @paths = []
      else
        begintime = Time.now
        @paths = Rails.cache.fetch("api-common-interests-#{viewer.cache_key}-#{@user.cache_key}-#{@current_page}-#{@per_page}", :expires_in => 10.minutes){ Connection.common_interests(viewer, @user, (params[:page].nil? ? nil : params[:page].to_i), (params[:per_page].nil? ? nil : params[:per_page].to_i))}
        ap "ci #{Time.now - begintime}"
      end
      respond_with @paths do |format|
        format.html {render 'users/show', :layout => false}
        format.any(:xml, :json) { render('users/commoninterests') }
      end
    end
    

    def stats
      getStats
      respond_with @stats do |format|
        format.html {render 'users/show', :layout => false}
        format.any(:xml, :json) { respond_with @stats }
      end
    end

  end
end