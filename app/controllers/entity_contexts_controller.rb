class EntityContextsController < ApplicationController
  before_filter :authenticate_user!

  def show
    @application = Application.find(params[:application_id])
    authenticate_ownership(@application)
    @context = @application.entity_contexts.find(params[:id])
  end

  def edit
    
  end

  def update
    
  end

  def new
    @application = Application.find(params[:application_id])
    authenticate_ownership(@application)
    @context = @application.entity_contexts.build
  end

  def create
    @application = Application.find(params[:application_id])
    authenticate_ownership(@application)
    @context =  @application.entity_contexts.build params[:entity_context]
    if @context.save
      redirect_to application_entity_context_path(@application, @context)
    else
      render 'new'
    end
  end
end
