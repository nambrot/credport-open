module Api::V1
  class ApiController < ::ApplicationController
    respond_to :json
    def getuser
      if @user
        return @user
      end
      case
      when params.has_key?(:linkedin)
        @user ||= User.find_by_identity(params[:linkedin], 'linkedin')
      when params.has_key?(:twitter)
        @user ||= User.find_by_identity(params[:twitter], 'twitter')
      when params.has_key?(:facebook)
        @user ||= User.find_by_identity(params[:facebook], 'facebook')
      when params.has_key?(:email)
        @user ||= User.find_by_email params[:email]
      when params.has_key?(:md5_email)
        @user ||= User.find_by_md5_hash params[:md5_email]
      else
        @user ||= User.find_by_param(params[:id])
        @user ||= User.find_by_param(params[:user_id])
      end
      if @user.nil?
        @status = 404
        @error = "User not found"
        if params[:callback]
         render('users/error')
        else
          render('users/error', :status => 404)
        end
      else
        @status = 200
        @error = ''
        @loggedin = (current_user ? true : false)
      end
    end
  
    def prepare_pagination(path)
      getuser

      @current_page = params[:page].nil? ? 1 : params[:page].to_i
      @per_page = params[:per_page].nil? ? 20 : params[:per_page].to_i
      @next_page = @current_page + 1
      @previous_page = @current_page == 1 ? 1 : @current_page - 1

      @pagination = {
        :page => @current_page,
        :per_page => @per_page,
        :next_page => @next_page,
        :previous_page => @previous_page,
        :next => api_v1_user_url(@user) + path + "?page=#{@next_page}&per_page=#{@per_page}",
        :previous => api_v1_user_url(@user) + path + "?page=#{@previous_page}&per_page=#{@per_page}"
      }

    end

    def current_resource_owner
      User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    end

    def me
      @user = current_resource_owner
      respond_with @user
    end

  end 
end