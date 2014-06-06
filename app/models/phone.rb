class Phone < ActiveRecord::Base
  attr_accessible :phone, :verified

  belongs_to :user, :touch => true

  validates :user, :presence => true
  validates :phone, :presence => true, :uniqueness => true
  validate :plausible_phone?
  def plausible_phone?
    errors.add(:phone, "is malformatted") unless Phony.plausible?(phone)
  end

  before_save :normalize_phone
  def normalize_phone
    self.phone = Phony.normalize phone
  end

  before_create :generate_verification_code
  def generate_verification_code
    self.verification_code = rand(10**5).to_s(10) unless @verified
  end

  def verified?
    persisted? and verification_code.nil?
  end

  def verified=(value)
    @verified = value
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
  
  def send_verification_code
    @account_sid = ENV['TWILIO_SID']
    @auth_token = ENV['TWILIO_TOKEN'] # your authtoken here

    # set up a client to talk to the Twilio REST API
    @client = Twilio::REST::Client.new(@account_sid, @auth_token)

    @account = @client.account
    @message = @account.sms.messages.create({:from => '+16173907847', :to => Phony.formatted(phone, :format => :international, :spaces => '') , :body => "To verify your phone on Credport, please enter the following code on the website: #{verification_code}"})
  end

  def phone_formatted
    Phony.formatted(phone, :format => :international)
  end

  def phone_blurred
    '+' + Phony.split(phone).slice(0,2).concat(Phony.split(phone).drop(2).map{|number| number.gsub(/./,'*')}).join('-')
  end
end
