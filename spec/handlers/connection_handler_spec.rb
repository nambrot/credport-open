require 'spec_helper'

describe ConnectionHandler do
  it "should add FacebookApi's connections response to the database correctly" do
    # RubyProf.start
    @friends_data = MultiJson.load(File.read('tmp/facebook_friends.json')).deep_symbolize_keys
    @like_data = MultiJson.load(File.read('tmp/facebook_likes.json')).deep_symbolize_keys

    @friends_data[:connections] = @friends_data[:connections].map { |e| e.deep_symbolize_keys }

    @like_data[:connections] = @like_data[:connections].map { |e| e.deep_symbolize_keys }
    
    @identity = Identity.find_or_create!({
      :uid => '1503035709',
      :context_name => 'facebook',
      :name => "Nam",
      :url => 'https://www.facebook.com/namchuhoai',
      :image => "https://graph.facebook.com/1503035709/picture?type=large",
      :subtitle => "I am super fucking awesome",
      :credentials => {},
      :properties => {}
      })
    @identity.should_not be_nil

    begintime = Time.now
    ConnectionHandler.build_user_user_connections(@friends_data, @identity)
    ConnectionHandler.build_user_object_connections(@like_data, @identity)
    ap "Adding Facebook Connections takes #{Time.now - begintime} s"

    # check the number of connections
    actualfriends = @friends_data[:connections].length
    friendsindb = Connection.where(:context_id => ConnectionContext.find_by_name('facebook-friendship').id, :from_id => @identity.id, :from_type => 'Identity').count

    actualfriends.should == friendsindb

    actuallikes = @like_data[:connections].length
    likesindb = Connection.where(:context_id => ConnectionContext.find_by_name('facebook-like').id, :from_id => @identity.id, :from_type => 'Identity').count

    actuallikes.should == likesindb
    # result = RubyProf.stop

    # # Print a flat profile to text
    # printer = RubyProf::GraphHtmlPrinter.new(result)
    
    # File.open "tmp/profile-graph.html", 'w' do |file|
    #     printer.print file
    #   end
  end

  it "should not throw an error when connecting the same stuff" do
    @identity = Identity.find_or_create!({
      :uid => '1503035710asds',
      :context_name => 'facebook',
      :name => "Nam",
      :url => 'https://www.facebook.com/namchuhoai',
      :image => "https://graph.facebook.com/1503035709/picture?type=large",
      :subtitle => "I am super fucking awesome",
      :credentials => {},
      :properties => {}
      })
    @identity.should_not be_nil

    @connections = {
      :context => ConnectionContext.find_by_name('facebook-friendship'),
      :connections => [
        {
          :identity => {
            :uid => '1503035710assdsdds',
            :context_name => 'facebook',
            :name => "Nam",
            :url => 'https://www.facebook.com/namchuhoai',
            :image => "https://graph.facebook.com/1503035709/picture?type=large",
            :subtitle => "I am super fucking awesome",
            :credentials => {},
            :properties => {}
          },
          :connection => {
            :from => 'me',
            :to => 'you',
            :properties => {}
          }
        },
        {
          :identity => {
            :uid => '1503035710assdsdds',
            :context_name => 'facebook',
            :name => "Nam",
            :url => 'https://www.facebook.com/namchuhoai',
            :image => "https://graph.facebook.com/1503035709/picture?type=large",
            :subtitle => "I am super fucking awesome",
            :credentials => {},
            :properties => {}
          },
          :connection => {
            :from => 'me',
            :to => 'you',
            :properties => {}
          }
        }
      ]
    }

    ConnectionHandler.build_user_user_connections(@connections, @identity)
  end

end
