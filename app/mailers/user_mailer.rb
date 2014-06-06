class UserMailer < ActionMailer::Base
  default from: "pleasereply@credport.org",
          reply_to: 'pleasereply@credport.org'

  def signup_mail(user, email)
  	@user = user
  	@email = email
  	mail(:to => @email.email, :subject => "Welcome to Credport! Verify your email")
  end

  def verifying_email_mail(user, mail)
  	@user = user
  	@email = mail
  	mail(:to => @email.email, :subject => "Verify your email on Credport")
  end

  def request_recommendation_email(user, email, message = nil)
    @user = user
    @email = email
    @message = message if message
    mail(:to => email, :subject => "#{user.first_name} is asking you for recommendations in Credport")
  end
end
