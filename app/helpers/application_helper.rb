module ApplicationHelper
  
  # Authentication
  def current_user
    if session.has_key?(:user_id) and ( @current_user.nil? or (session[:user_id] != @current_user.id))
      @current_user = User.find_by_id(session[:user_id])
    end
    @current_user 
  end

  def set_return_redirect(meta = {})
    if session[:redirect_hash].nil?
      meta[:expires_in] = 10.minutes.from_now unless meta.has_key? :expires_in
      session[:redirect_hash] = meta
    end
  end

  def authenticate_user!(meta = {})
    if !current_user
      meta[:uri] = request.url unless meta.has_key? :uri
      meta[:title] = "LogIn Required" unless meta.has_key? :title
      meta[:text] = "Please login (or signup) to see #{meta[:uri]}" unless meta.has_key? :text
      meta[:return_text] = "Return to #{URI(meta[:uri]).host}" unless meta.has_key? :return_text
      meta[:display] = true
      meta[:expires_in] = 10.minutes.from_now unless meta.has_key? :expires_in
      session[:redirect_hash] = meta
      flash[meta[:title]] = meta[:text]
      redirect_to new_session_path
    end
  end

  def authenticate_ownership(object, admin_access = true)
    render :file => "public/401.html", :status => :unauthorized, :layout => false unless object.user == current_user or (admin_access and Rails.configuration.credport_admins.include?(current_user.id.to_s))
  end

  def redirect_back(*params)
    
    uri = session[:redirect_hash][:uri] if session.has_key? :redirect_hash and session[:redirect_hash][:expires_in] > DateTime.now
    session[:redirect_hash] = nil

    if uri
      redirect_to uri
    else
      if request.env['omniauth.origin']
        redirect_to request.env['omniauth.origin']
      else
        redirect_to(*params)
      end
    end
  end

  def authenticate_admin!
    raise ActionController::RoutingError.new('Not Found') unless current_user and Rails.configuration.blog_admins.include? current_user.id.to_s
  end


  # Stats

  def mixpanel
    @mixpanel = Mixpanel::Tracker.new Rails.configuration.mixpanel_key, {}
  end

  # API
  def escape_objects(object)
    if object.class == Hash or object.class.ancestors.include? Hash
      ret = {}
      object.each{|sym, val| ret[sym] = escape_objects(val) }
      ret
    elsif object.class == Array
      object.map{|val| escape_objects val}
    else
      ERB::Util.h object
    end
  end

  def include_parameter(key)
    params.has_key?(:include) and params[:include].split(',').include?(key)
  end

  def include_education?
    include_parameter 'education'
  end

  def include_work?
    include_parameter 'work'
  end

  def include_stats?
    include_parameter 'stats'
  end

  def include_verifications?
    include_parameter 'verifications'
  end

  def include_reviews?
    include_parameter 'reviews'
  end

  def getStats
    viewer = params.has_key?(:viewer) ? User.find_param(params[:viewer]) : current_user
    if viewer.nil? or viewer == @user
      @stats = Rails.cache.fetch("api-stats-without-#{@user.cache_key}", :expires_in => 2.hours){ Connection.stats_without_viewer(@user)}
    else
      @stats = Rails.cache.fetch("api-stats-without-#{@user.cache_key}-#{viewer.cache_key}", :expires_in => 2.hours){Connection.stats_with_viewer(viewer, @user)}
    end
    @stats[:common_connections] = {
      :number => @stats[:common_connections],
      :title => t('Common Connections'),
      :desc => t('Number of connections you both share'),
      :image => "https://credport-assets.s3.amazonaws.com" + ActionController::Base.helpers.asset_path("community.png")
    }
    @stats[:common_interests] = {
      :number => @stats[:common_interests],
      :title => t('Common Interests'),
      :desc => t('Number of interests you both share'),
      :image => "https://credport-assets.s3.amazonaws.com" + ActionController::Base.helpers.asset_path("commoninterest.png")
    }
    @stats[:reviews] = {
      :number => @stats[:reviews],
      :title => t('Reviews'),
      :desc => t('Number of reviews'),
      :image => "https://credport-assets.s3.amazonaws.com" + ActionController::Base.helpers.asset_path("reviews.png")
    }
    @stats[:degree_of_seperation] = {
      :number => @stats[:degree_of_seperation],
      :title => t('Degrees of separation'),
      :desc => t('How many steps away you are'),
      :image => "https://credport-assets.s3.amazonaws.com" + ActionController::Base.helpers.asset_path("dos.png")
    }
    @stats[:accounts] = {
      :number => @stats[:accounts],
      :title => t('Accounts'),
      :desc => t('Number of verified accounts'),
      :image =>"https://credport-assets.s3.amazonaws.com" +  ActionController::Base.helpers.asset_path("accounts.png")
    }
    @stats[:verifications] = {
      :number => @stats[:verifications],
      :title => t('Verifications'),
      :desc => t('Number of emails/phones'),
      :image => "https://credport-assets.s3.amazonaws.com" + ActionController::Base.helpers.asset_path("verifications.png")
    }
    @stats
  end

  # Actual helper functions
  def get_domain(url)
    return 'undefined' unless url
    url = URI(url).host
    if url.split('.').length > 1
      url.split( "." 
)[-2,2].join(".")
    else
      url
    end
  end
end
