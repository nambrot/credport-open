class Api::V1::IdentitiesController < Api::V1::ApiController
  before_filter :getuser
  respond_to :json
  skip_before_filter :verify_authenticity_token

  def index
    @identities = @user.identities
    respond_with @identities
  end

  def create
    if !ENV['STAGING'] and Rails.env == 'production' and !Doorkeeper::Application.exists? :uid => params[:key]
      @error = 'Unauthorized'
      @status = 401
      respond_with({:errors => 'Unauthorized'}, :status => 401)
      return
    end
    @identity = Identity.find_by_uid_and_context_name(params[:uid], params[:context_name])
    if @identity
      @user.identities << @identity
      @user.mixpanel_track('API::Identity::Create', {:provider => params[:context_name]})
      @user.mixpanel_track("API::Identity::Create::#{params[:context_name]}")
      respond_with(@identity, :location => api_v1_user_identities_path(@user), :status => 200)
    else
      @identity = Identity.new :uid => params[:uid], :context_name => params[:context_name], :name => params[:name], :url => params[:url], :image => params[:image], :subtitle => params[:subtitle]
      @identity.user = @user
      @identity.save

      if @identity.persisted?
        @user.mixpanel_track('API::Identity::Create', {:provider => params[:context_name]})
        @user.mixpanel_track("API::Identity::Create::#{params[:context_name]}")
      end

      respond_with(@identity, :location => api_v1_user_identities_path(@user), :status => (@identity.persisted? ? 201 : 406))
    end
  end

end
