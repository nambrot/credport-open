class UsersController < ApplicationController
  caches_action :show, :cache_path => :show_cache_path.to_proc, :expires_in => 2.hours, :if => Proc.new{|x| x.show_cache_current_user_condition }

  before_filter :getuser, :only => :show
  before_filter :authenticate_user!, :only => :me

  def getuser
    params[:id] = params[:user_id] if !params[:user_id].nil?
    @user ||= User.find_param(params[:id])
  end

  def show_cache_current_user_condition
    getuser
    return current_user != @user
  end

  def show_cache_path
    getuser
    return "user-#{@user.cache_key}-#{current_user ? current_user.cache_key : 0}-#{I18n.locale}"
  end

  def new
    # TODO: Make this redirect_back (in session_controller too)
    redirect_to root_path, :notice => "You are already logged in" if current_user
    @user = User.new
    @user.name = nil if @user.name == 'Anonymous User'
    @email = @user.emails_to_verify.build
    set_meta_tags({
          :title => "Credport - Signup",
          :description => "Building Trust Online",
          :keywords => ['collaborative consumption', 'sharing economy', 'trust', 'reputation', 'ratings'],
          :canonical => 'http://www.credport.org/signup',
          :open_graph => {
            :title => "Credport Signup",
            :description => "Building Trust Online",
            :url => "http://www.credport.org/signup",
            :type => 'website',
            :image => ActionController::Base.helpers.asset_path("credportsquare.png"),
            :site_name => 'Credport'
          }
          })
  end

  def create
    @email = Email.new :email => params[:email]
    @user = User.new params[:user]
    if @user.save and @email.save
      @user.emails_to_verify << @email
      session[:user_id] = @user.id
      session[:new_user] = true
      current_user.mixpanel_track('Profile (signed up)', {:provider => 'credport'})
      current_user.mixpanel_set({'SignUp Via' => 'email'})
      @email.delay(:queue => 'signup_mail').send_signup_email
      redirect_to user_path(@user) + "/edit", :notice => "Successfully signed up"
    else
      @user.name = nil if @user.name == 'Anonymous User'
      render 'new'
    end
  end

  def show
    params[:include] = 'reviews,verifications,education,work'
    raise ActionController::RoutingError.new('Not Found') if @user.nil?
    if params.include?(:source) and params[:source] = 'badgeoverlayiframe'
      @user.mixpanel_track("API::Users::Overlay::Show", { :referrer => get_domain(request.referrer), :current_user => current_user.try(:to_param) }) 
      @user.mixpanel_increment({"API::Users::Overlay::Show" => 1})
    end

    if params.include?(:source) and params[:source] = 'badgeoverlay'
      @user.mixpanel_track("API::Users::Overlay::Referrer", { :referrer => get_domain(request.referrer), :current_user => current_user.try(:to_param) }) 
      @user.mixpanel_increment({"API::Users::Overlay::Referrer" => 1})
    end
    
    set_meta_tags({
      :title => @user.name,
      :description => "#{@user.name}'s profile on Credport, your passport to trust online.",
      :keywords => [@user.name, "trust", 'profile', 'reputation', 'trustworthy', 'credible'],
      :canonical => user_url(@user),
      :open_graph => {
        :title => @user.name,
        :url => user_url(@user),
        :type => 'profile',
        :image => @user.image,
        :description => "#{@user.name}'s Credport, your passport to trust online.",
        :site_name => 'Credport'
      }
      })
  end

  def me
    redirect_to current_user
  end
end
