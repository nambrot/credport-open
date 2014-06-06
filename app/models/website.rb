class Website < ActiveRecord::Base
  belongs_to :user, :touch => true
  validates_associated :user
  validate :user, :presence => true
  
  attr_accessible :image, :title, :url

  validate :title, :presence => true
  validate :url, :presence => true, :uniqueness => true
  validates_format_of :url, :with => URI::regexp(%w(http https))

  before_create :generate_verifciation_code

  def generate_verifciation_code
    self.verification_code = rand(10**10).to_s(36) unless @verified
  end

  def verified?
    !verification_code.nil?
  end

  def verify
    begin
      document = HTTParty.get(url, :timeout => 5)
      if document.body.scan(verification_code).length() > 0
        # verified
        self.verification_code = nil
        self.save
        return {:success => true}
      else
        return {:success => false, :message => I18n.t("webpage.errors.notfound")}
      end
    rescue Exception => ex
      return {:success => false, :message => I18n.t('webpage.errors.timeout')}
    end
    
  end

end
