class ReviewsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json
  
  def create
    @user = User.find(params[:user_id])

    if @user.credport_recommendation_written_by(current_user).length > 0
      render :json => {:errors => ["You already wrote #{@user.first_name} a recommendation"]}, :status => 401
      return
    end

    case params[:relationship]
    when 'friend'
      context = 'credport_friend_recommendation'
    when 'colleague'
      context = 'credport_colleague_recommendation'
    when 'family'
      context ='credport_family_recommendation'
    when 'other'
      context = 'credport_other_recommendation'
    end
    
    recommendation = Recommendation.create({
      :recommender => current_user.credport_identity,
      :recommended => @user.credport_identity,
      :role => context,
      :text => params[:recommendation_text]
      })

    if recommendation.persisted?
      current_user.mixpanel_track 'Recommendation:Written', { :recommended => @user.to_param }
      @user.mixpanel_track 'Recommendation:Write', { :recommender => current_user.to_param }
      current_user.mixpanel_increment({ 'Recommendation:Written' => 1 })
      @user.mixpanel_increment({ 'Recommendation:Write' => 1 })
      respond_with recommendation, :location => user_review_path(@user)
    else
      render :json => {:errors => recommendation.errors.full_messages}, :status => 422
    end
  end

  def show
    @user = User.find params[:user_id]
    reviews = @user.credport_recommendation_written_by current_user
    if reviews.length > 0
      respond_with reviews.first
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def update
    @user = User.find params[:user_id]
    reviews = @user.credport_recommendation_written_by current_user
    
    if reviews.length == 0
      render :json => {:errors => ["You have not written a recommendation yet."]}, :status => 404
    end

    review = reviews.first
    
    case params[:relationship]
    when 'friend'
      context = 'credport_friend_recommendation'
    when 'colleague'
      context = 'credport_colleague_recommendation'
    when 'family'
      context ='credport_family_recommendation'
    when 'other'
      context = 'credport_other_recommendation'
    end

    if review.update_attributes({:role => context, :text => params[:recommendation_text]})
      current_user.mixpanel_track 'Recommendation:Update', { :recommended => @user.to_param }
      current_user.mixpanel_increment({ 'Recommendation:Update' => 1 })
      respond_with review
    else
      render :json => {:errors => review.errors.full_messages}, :status => 422
    end
  end

  def me_to_approve
    respond_with current_user.credport_recommendations_to_approve, :only => [:id, :role, :text]
  end

  def destroy
    recommendation = Recommendation.find(params[:id])

    if recommendation.recommended.user != current_user
      render :json => {:errors => ["You are not authorized to delete this recommendation"]}, :status => :unauthorized
      return
    end

    recommendation.destroy

    if recommendation.destroyed?
      current_user.mixpanel_track 'Recommendation:Destroy', { :recommended => @user.to_param }
      current_user.mixpanel_increment({ 'Recommendation:Destroy' => 1 })
    end

    respond_with recommendation
  end

  def approve
    recommendation = Recommendation.find(params[:id])

    if recommendation.recommended.user != current_user
      render :json => {:errors => ["You are not authorized to delete this recommendation"]}, :status => :unauthorized
      return
    end

    if recommendation.approve
      begin
        user = recommendation.recommender.user
        current_user.mixpanel_track 'Recommendation:Approve', { :recommended => user.to_param }
        user.mixpanel_track 'Recommendation:Approved', { :recommender => current_user.to_param }
        current_user.mixpanel_increment({ 'Recommendation:Approve' => 1 })
        user.mixpanel_increment({ 'Recommendation:Approved' => 1 })
      rescue Exception => e
        
      end
      
      render :json => Rabl::Renderer.new('users/review', recommendation.connection_in_db, :view_path => 'app/views', :format => 'hash', :scope => self).render
    else
      render :json => {:errors => ["Could not approve recommendation."]}, :status => 422
    end
  end

  def request_by_email
    
    if params[:emails].empty?
      render :json => {:errors => ['You have not entered any emails']}, :status => 422
      return
    end 

    message = params[:message] unless params[:message].empty?
    
    emails = params[:emails].split(',').map(&:strip).each {|email| current_user.delay(:queue => 'request_recommendation_email').request_recommendation_by_email(email)}

    current_user.mixpanel_track 'Recommendation:EmailRequest', { :length => emails.length }
    
    current_user.mixpanel_increment({ 'Recommendation:EmailRequest' => emails.length})
    
    render :json => {:success => true}
  end

end
