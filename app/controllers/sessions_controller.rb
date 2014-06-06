class SessionsController < ApplicationController
  def new
    # possible save redirect if we are on a profile previously
    if request.referer and path = URI(request.referer).path and path.match(/\/u\//)
      set_return_redirect :uri => request.referer
    end
    redirect_back root_path, :notice => 'You are already logged in' if current_user
  end
  
  def create
    user = User.authenticate(params[:email], params[:password])  
    if user  
      session[:user_id] = user.id
      redirect_back root_url, :notice => "Logged in!"
    else
      flash[:notice] = "Invalid email or password"  
      render "new"
    end
  end
  
  def destroy
    session[:user_id] = nil
    redirect_to request.referer || root_url, :notice => "Logged out!"
  end
end
