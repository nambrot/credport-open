class ConnectionContextsController < ApplicationController
  before_filter :authenticate_user!

  def show
    @application = Application.find(params[:application_id])
    authenticate_ownership(@application)
    @context = @application.connection_contexts.find(params[:id])
  end


  def edit
    @application = Application.find(params[:application_id])
    authenticate_ownership(@application)
    @context = @application.connection_contexts.find(params[:id])
  end

  def update
   
  end

  def new
    @application = Application.find(params[:application_id])
    authenticate_ownership(@application)
    @context = @application.connection_contexts.build
  end

  def create
    @application = Application.find(params[:application_id])
    authenticate_ownership(@application)
    @context =  @application.connection_contexts.build params[:connection_context]

    @context.connection_context_protocols << ConnectionContextProtocol.find_by_name('text-protocol') if params[:text_protocol]

    if @context.save
      redirect_to application_connection_context_path(@application, @context)
    else
      render 'new'
    end
  end

  def redirect_back_from_signup
    redirect_back root_path
  end
end