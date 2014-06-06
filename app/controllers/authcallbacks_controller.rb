class AuthcallbacksController < ApplicationController

  def create
    o = request.env['omniauth.auth'].deep_symbolize_keys
    Rails.logger.ap o

    begin
     
      identity = Identity.includes(:user).find_by_uid_and_context_name(o[:uid], o[:provider])
      user = identity.nil? ? nil : identity.user

      case 
      
      # New User
      when (user.nil? and current_user.nil?)
        Rails.logger.info "New User"
        password = rand(10**10).to_s(36)
        user = User.create! :password => password
        update_identity( identity, user, o , params[:provider],:add_email => true , :add_identity => true)
        
        session[:new_user] = user.id
        session[:user_id] = user.id

        current_user.mixpanel_track('Profile (signed up)', {:provider => o[:provider]})
        current_user.mixpanel_set({'SignUp Via' => o[:provider]})
        current_user.mixpanel_increment({'Add Network' => 1, "Add #{o[:provider]}" => 1})

        redirect_to user_path(user) + '/edit'
      
      # Add Identity to Current User
      when (current_user and user.nil?)
        Rails.logger.info "Adding Identity to User"
        update_identity( identity, current_user, o , params[:provider], :add_email=> true , :add_identity => true)

        current_user.mixpanel_track('Add Verification', {:provider => o[:provider]})
        current_user.mixpanel_increment({'Add Network' => 1, "Add #{o[:provider]}" => 1})

        redirect_to user_path(current_user) + '/edit', :notice => "Successfully connected"
      
      # Login
      when (current_user.nil? and user)
        Rails.logger.info "Login"
        session[:user_id] = user.id
        update_identity( identity, user, o , params[:provider] )

        current_user.mixpanel_track('Login', {:provider => o[:provider]})
        current_user.mixpanel_track('Login with ' + o[:provider])
        current_user.mixpanel_increment({'Add Network' => 1, "Add #{o[:provider]}" => 1})

        redirect_back user_path(current_user) + '/edit', :notice => "Successfully logged In"
      
      # Update Identity
      when (current_user and user and user == current_user)
        Rails.logger.info "Update Identity"
        update_identity( identity, user, o , params[:provider] )

        current_user.mixpanel_increment({'Add Network' => 1, "Add #{o[:provider]}" => 1})

        redirect_to request.env['omniauth.origin'] || user_path(current_user) + '/edit', :notice => "Successfully connected"
      
      # Mismatch
      when (current_user and user and user != current_user)
        Rails.logger.warn "WARN Mismatching Credentials Unable to Authorize Request" 
        
        redirect_to request.env['omniauth.origin'] || user_path(current_user) + '/edit', :notice => "The #{params[:provider].capitalize} account belongs to someone else"
      else
        Rails.logger.warn "Some weird edge case"

        redirect_to :root, :notice => "Something went wrong"
      end

    rescue Exception => ex
      Rails.logger.fatal %("FATAL: AUTHCALLBACK for #{o[:provider]}:#{o[:uid]}
      Message #{ex.message}
      Backtrace ... #{ex.backtrace[0..10].join("\n")}")
      Rails.logger.warn "WARN: AUTHCALLBACK error 'o' hash"
      Rails.logger.ap o
      if current_user
        redirect_to user_path(current_user), :notice => "Something went wrong"
      else
        redirect_to :root, :notice => "Something went wrong"
      end
    end

  end

  def update_identity( identity, user , o, provider, other={} )
      
      if other[:add_identity]
        identity = Identity.find_or_create!(o[:extra][:credport][:identity])
        created_time = identity.created_at
        updated_time = identity.updated_at
        user.identities << identity
      else
        created_time = identity.created_at
        updated_time = identity.updated_at
      end

      identity.update_attributes o[:extra][:credport][:identity]
      
      if other[:add_email] and o[:extra][:credport].has_key?(:email)
        user.emails.create(:email => o[:extra][:credport][:email], :verified => true) 
      end

      if other[:add_email] and o[:extra][:credport].has_key?(:phone) and !o[:extra][:credport][:phone].nil?
        user.phones.create(:phone => o[:extra][:credport][:phone], :verified => true)
      end

      AttributeHandler.get_attributes( identity, user, o, provider )
      identity.fetch_attributes
      
      if window_open?( created_time, updated_time )
         #identity.fetch_connections(o[:credentials])
        identity.delay(:queue => :fetch_connections).fetch_connections(o[:credentials])
      end

  end

  def window_open?( created_time, updated_time )
    
    minutes = (Time.now()-updated_time) / 60
    if minutes > Rails.configuration.update_window
      # has been more than a certain time that we are updating
      Rails.logger.debug "DEBUG Update Window Open, Last Update At #{updated_time}, #{minutes} minutes ago"
      true
    elsif ((updated_time - created_time)/60) < 1
      # it's a brand new record
      Rails.logger.debug "DEBUG Creation Window Open,  Created at  #{created_time}, Updated_at #{updated_time}" 
      true
    else
      Rails.logger.debug "DEBUG Update Window Closed. Last Updated_At #{updated_time}, #{minutes} minutes ago"
      false
    end
  end

  def fail
    ap params
    error = "We could not connect to #{params["strategy"].capitalize}"
    Rails.logger.warn "WARNING OAUTH FAILED #{params}"
    if session[:user_id].nil?
      redirect_to  params["origin"] || :root , :notice => error
    else
      user = User.find( session[:user_id])
      redirect_to user_path(user), :notice => error
    end
  end

end
