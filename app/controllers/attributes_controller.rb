class AttributesController < ApplicationController
  before_filter :authenticate_user!, :except => [:verify_email]
  respond_to :json, :html, :xml

  def set_educationattribute_visibility
    attribute = EducationAttribute.find params[:id]
    if attribute.user != current_user
      respond_with({ errors: ['Attribute does not belong to current user']}, :status => 500)
      return
    end
    params[:visibility] == 'true' ? attribute.set_public : attribute.set_private
    render :template => 'users/education_attribute', :locals => {:object => attribute}
  end
    
  def set_workattribute_visibility
    attribute = WorkAttribute.find params[:id]
    # TODO: makes this do XML as well
    if attribute.user != current_user
      respond_with({:errors => ['Attribute does not belong to current user']}, :status => 500)
      return
    end
    params[:visibility] == 'true' ? attribute.set_public : attribute.set_private
    render :template => 'users/work_attribute', :locals => {:object => attribute}
  end

  def change_name
    current_user.name = params[:name]
    current_user.save
    current_user.mixpanel_track('Change Name')
    current_user.mixpanel_increment({'Change Name' => 1})
    respond_with(current_user, :location => user_path(current_user))
  end

  def change_tagline
    current_user.tagline = params[:tagline]
    current_user.save
    current_user.mixpanel_track('Change Tagline')
    current_user.mixpanel_increment({'Change Tagline' => 1})
    respond_with(current_user, :location => user_path(current_user))
  end

  def add_website_to_verify
    @website = current_user.websites_to_verify.build(params[:website])
    if @website.save
      current_user.mixpanel_track('Submit Website')
      current_user.mixpanel_increment({'Submit Website' => 1})
      respond_to do |format|
        format.html { redirect_to user_path(current_user), :notice => "Webpage added. Please add the code to the page." }
        format.xml { respond_with({:success => "Webpage added. Please add the code to the page.", :website => Rabl::Renderer.new('users/website', @website, :view_path => 'app/views', :format => 'hash').render}, :location => user_path(current_user))}
        format.json { respond_with({:success => "Webpage added. Please add the code to the page.", :website => Rabl::Renderer.new('users/website', @website, :view_path => 'app/views', :format => 'hash').render}, :location => user_path(current_user))}
      end
    else
      respond_with @website
    end
  end

  def check_website
    @website = current_user.websites_to_verify.find(params[:id])
    result = @website.verify
    current_user.mixpanel_track('Attempt Verify Website')
    current_user.mixpanel_increment({'Attempt Verify Website' => 1})
    if result[:success]
      current_user.mixpanel_track('Verify Website')
      current_user.mixpanel_increment({'Verify Website' => 1})
      respond_to do |format|
        format.html { redirect_to user_path(current_user) + '/verify', :notice => "Websites successfully verified" }
        format.json { respond_with(
          {
            :success => "Website verified",
            :website => Rabl::Renderer.new('users/website', @website, :view_path => 'app/views', :format => 'hash', :scope => ActionController::Base.helpers).render,
            :verification => Rabl::Renderer.new('users/website_verification', @website, :view_path => 'app/views', :format => 'hash', :scope => ActionController::Base.helpers).render
          }, :location => nil)}
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path, :notice => "Could not verify Website"}
        format.json { respond_with(
          {
            :errors => result[:message]
          }, :location => nil, :status => :bad_request)}
      end
    end
  end

  def add_email_to_verify
    @email = current_user.emails_to_verify.build(:email => params[:email])
    if @email.save
      @email.delay(:queue => 'verification_email').send_verification_code
      current_user.mixpanel_track('Submit Email')
      current_user.mixpanel_increment({'Submit Email' => 1})
      respond_to do |format|
        format.html { redirect_to user_path(current_user), :notice => "Email Added. Please see your Inbox." }
        format.xml { respond_with({:success => "Email Added. Please see your inbox", :email => Rabl::Renderer.new('users/email', @email, :view_path => 'app/views', :format => 'hash').render}, :location => user_path(current_user))}
        format.json { respond_with({:success => "Email Added. Please see your inbox", :email => Rabl::Renderer.new('users/email', @email, :view_path => 'app/views', :format => 'hash').render}, :location => user_path(current_user))}
      end
    else
      respond_with @email
    end
  end

  def resend_email_code
    email = Email.find_by_email(params[:email])
    if email
      email.delay(:queue => 'verification_email').send_verification_code
      current_user.mixpanel_track('Resend Email')
      current_user.mixpanel_increment({'Resend Email' => 1})
      respond_to do |format|
      format.html {redirect_to user_path(current_user), :notice => 'Code has been sent. Please see your Inbox.'}
      format.json {respond_with({:success => "Code has been sent. Please see your Inbox"}, :location => user_path(current_user))}
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path, :notice => "Email could not be found"}
        format.json { respond_with(
          {
            :errors => "Email could not be found"
          }, :status => :bad_request)}
      end
    end
  end

  def verify_email
    email = Email.verify(params[:code])
    if email 
      email.user.mixpanel_track('Verify Email')
      email.user.mixpanel_increment({'Verify Email' => 1})
      respond_to do |format|
        format.html { redirect_to user_path(email.user) + '/verify', :notice => "Email successfully verified" }
        format.json { respond_with(
          {
            :success => "Email verified",
            :email => Rabl::Renderer.new('users/email', email, :view_path => 'app/views', :format => 'hash', :scope => ActionController::Base.helpers).render,
            :verification => Rabl::Renderer.new('users/email_verification', email, :view_path => 'app/views', :format => 'hash', :scope => ActionController::Base.helpers).render
          })}
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path, :notice => "Could not verify Email"}
        format.json { respond_with(
          {
            :errors => "Email could not be verified"
          }, :status => :bad_request)}
      end
    end
  end

  def add_phone_to_verify 
    phone = current_user.phones_to_verify.build(:phone => "#{params[:country]}#{params[:phone]}")
    if phone.save
      phone.send_verification_code
      current_user.mixpanel_track('Submit Phone')
      current_user.mixpanel_increment({'Submit Phone' => 1})
      respond_with({:success => "Phone added. Please verify by entering the code.", :phone => Rabl::Renderer.new('users/phone', phone, :view_path => 'app/views', :format => 'hash').render}, :location => user_path(current_user))
    else
      respond_with({:errors => {:phone => ['number is malformatted']}}, :status => :unprocessable_entity, :location => user_path(current_user))
    end
  end

  def resend_phone_code
    phone = Phone.find_by_phone(params[:phone])
    phone.send_verification_code
    current_user.mixpanel_track('Resend Phone')
    current_user.mixpanel_increment({'Resend Phone' => 1})
    respond_to do |format|
      format.html {redirect_to user_path(current_user), :notice => 'Code has been sent.'}
      format.json {respond_with({:success => "Code has been sent."}, :location => user_path(current_user))}
    end
  end

  def verify_phone
    phone = current_user.phones_to_verify.find_by_verification_code(params[:code])
    ap phone
    if phone and phone.verify_code(params[:code])
      current_user.mixpanel_track('Verify Phone')
      current_user.mixpanel_increment({'Verify Phone' => 1})
      respond_to do |format|
        format.html { redirect_to user_path(phone.user) + '/verify', :notice => "Phone successfully verified" }
        format.json { respond_with(
          {
            :success => "Phone verified",
            :phone => Rabl::Renderer.new('users/phone', phone, :view_path => 'app/views', :format => 'hash', :scope => ActionController::Base.helpers).render,
            :verification => Rabl::Renderer.new('users/phone_verification', phone, :view_path => 'app/views', :format => 'hash', :scope => ActionController::Base.helpers).render
          })}
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path, :notice => "Could not verify Phone"}
        format.json { respond_with(
          {
            :errors => "Phone number could not be verified"
          }, :status => :bad_request)}
      end
    end
  end

  def backgroundpicture_form
    render json: {
          policy: s3_upload_policy_document_for_background_picture,
          signature: s3_upload_signature_for_background_picture,
          key: "uploads/#{SecureRandom.uuid}/#{URI.escape params[:filename]}",
          success_action_redirect: "/",
          aws_key: ENV['AWS_ACCESS_KEY_ID']
      }
  end

  def s3_upload_policy_document_for_background_picture
    Base64.encode64(
      {
        expiration: 30.minutes.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z'),
        conditions: [
          { bucket: 'credport-backgroundpictures' },
          { acl: 'public-read' },
          ["starts-with", "$key", "uploads/"],
          { success_action_status: '201' }
        ]
      }.to_json
    ).gsub(/\n|\r/, '')
  end

  def s3_upload_policy_document_for_background_picture
    Base64.encode64(
      {
        expiration: 30.minutes.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z'),
        conditions: [
          { bucket: 'credport-backgroundpictures' },
          { acl: 'public-read' },
          ["starts-with", "$key", "uploads/"],
          { success_action_status: '201' }
        ]
      }.to_json
    ).gsub(/\n|\r/, '')
  end
  # sign our request by Base64 encoding the policy document.
  def s3_upload_signature_for_background_picture
    Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest::Digest.new('sha1'),
        ENV['AWS_SECRET_ACCESS_KEY'],
        s3_upload_policy_document_for_background_picture
      )
    ).gsub(/\n/, '')
  end

  def profilepicture_form
    render json: {
          policy: s3_upload_policy_document,
          signature: s3_upload_signature,
          key: "uploads/#{SecureRandom.uuid}/#{URI.escape params[:filename]}",
          success_action_redirect: "/",
          aws_key: ENV['AWS_ACCESS_KEY_ID']
      }
  end

  def s3_upload_policy_document
    Base64.encode64(
      {
        expiration: 30.minutes.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z'),
        conditions: [
          { bucket: 'credport-profilepictures' },
          { acl: 'public-read' },
          ["starts-with", "$key", "uploads/"],
          { success_action_status: '201' }
        ]
      }.to_json
    ).gsub(/\n|\r/, '')
  end

  # sign our request by Base64 encoding the policy document.
  def s3_upload_signature
    Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest::Digest.new('sha1'),
        ENV['AWS_SECRET_ACCESS_KEY'],
        s3_upload_policy_document
      )
    ).gsub(/\n/, '')
  end

  def add_profile_picture
    current_user.profile_pictures.create! :url => params[:picture]
    current_user.mixpanel_track('Add Profile Picture')
    current_user.mixpanel_increment({'Add Profile Picture' => 1})
    respond_with(current_user.profile_pictures.map(&:url), :location => user_path(current_user))
  end

  def add_background_picture
    current_user.background_picture = params[:picture]
    current_user.save
    current_user.mixpanel_track('Add Background Picture')
    current_user.mixpanel_increment({'Add Background Picture' => 1})
    respond_with current_user.background_picture, :location => user_path(current_user)
  end

  def remove_profile_picture
    current_user.profile_pictures.find_by_url(params[:picture]).destroy
    current_user.mixpanel_track('Remove Profile Picture')
    current_user.mixpanel_increment({'Remove Profile Picture' => 1})
    respond_with(current_user.profile_pictures.map(&:url), :location => user_path(current_user))
  end
end
