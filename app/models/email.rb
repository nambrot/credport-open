class Email < ActiveRecord::Base
  attr_accessible :email, :verified

  belongs_to :user, :touch => true

  email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, :presence => true, :uniqueness => true, :format => { :with => email_regex }
  
  before_save :generate_md5_hash
  before_save :downcase_email
  before_create :generate_verifciation_code

  def downcase_email
    self.email = email.downcase
  end

  def generate_md5_hash
    self.md5_hash = Digest::MD5.hexdigest(email.downcase)
  end

  def generate_verifciation_code
    self.verification_code = rand(10**80).to_s(36) unless @verified
  end

  def self.verify(code)
    email = self.find_by_verification_code(code)
    if email
      email.verify_code(code)
      return email
    else
      nil
    end
  end

  def verify_code(code)
    if self.verification_code == code
      self.verification_code = nil
      self.save
      true
    else
      false
    end
  end

  def verified?
    persisted? and verification_code.nil?
  end

  def verified=(value)
    @verified = value
  end

  def send_verification_code
    UserMailer.verifying_email_mail(user, self).deliver
  end

  def send_signup_email
    UserMailer.signup_mail(user, self).deliver
  end
end
