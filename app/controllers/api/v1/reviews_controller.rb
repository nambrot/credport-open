class Api::V1::ReviewsController < Api::V1::ApiController
  before_filter :getuser, :only => [:index]
  respond_to :json
  skip_before_filter :verify_authenticity_token

  def index
    prepare_pagination('/reviews')
    @reviews = @user.reviews
    respond_with @reviews
  end

  def create
    if params[:user_id]
      getuser
    end

    if !ENV['STAGING'] and Rails.env == 'production' and !Doorkeeper::Application.exists? :uid => params[:key]
      @error = 'Unauthorized'
      @status = 401
      respond_with({:errors => 'Unauthorized'}, :status => 401)
      return
    end
    context_name = params[:connection][:context_name] if params[:connection] and params[:connection].has_key? :context_name
    properties = params[:connection][:properties].deep_symbolize_keys if params[:connection] and params[:connection].has_key? :properties
    properties ||= {}
    @from = Identity.find_or_try_create(params[:from])
    @to = Identity.find_or_try_create(params[:to])
    @review = Connection.create_with_context @from, @to, ConnectionContext.find_by_name(context_name), properties
    @to.touch if @review.persisted?

    if @review.persisted? and @to.user
      @to.user.mixpanel_track('API::Review::Created', {:provider => connection[:context_name]})
      @to.user.mixpanel_track("API::Review::Created::#{connection[:context_name]}")
      @to.user.mixpanel_set({"Review Posted" => 'true', "Review Posted #{connection[:context_name]}" => 'true'})
      @to.user.mixpanel_increment({"Review Posted" => '1'})
    end

    respond_with(@review, :location => api_v1_user_reviews_path(@user))
  end
end