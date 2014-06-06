class OauthApplicationsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @applications = current_user.applications
    @applications = Application.all if Rails.configuration.credport_admins.include? current_user.id.to_s
  end

  def show
    @application = Application.find(params[:id])
    authenticate_ownership(@application)
  end


  def edit
    @application = Application.find(params[:id])
  end

  def update
    @application = Application.find(params[:id])
    if @application.update_attributes params[:application]
      redirect_to application_path(@application)
    else
      render 'edit'
    end
  end

  def new
    @application = Application.new
    @entity = @application.build_entity
  end

  def create
    @application = current_user.applications.build params[:application]
    @application.entity.context = EntityContext.find_by_name('credport_application_context') if @application.entity
    if @application.save
      redirect_to application_path(@application)
    else
      render 'new'
    end
  end

  def redirect_back_from_signup
    redirect_back root_path
  end
end