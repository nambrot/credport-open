class ProfilePicture < ActiveRecord::Base
  attr_accessible :url, :user
  belongs_to :user, :touch => true
  validates :user, :presence => true
  validates :url, :presence => true, :uniqueness => { :scope => :user_id }

  after_destroy :delete_from_s3
  def delete_from_s3
    match = self.url.match /https?:\/\/(.*)\/(.*)/
    if match[1] == "credport-profilepictures.s3.amazonaws.com"
      storage = Fog::Storage.new( :provider => 'AWS',
                          :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'], 
                          :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
                          :region => 'us-east-1' )
      directory = storage.directories.get( 'credport-profilepictures' )
      remote_file = directory.files.get( URI.unescape match[2] )
      remote_file.destroy
    end
  end
end
