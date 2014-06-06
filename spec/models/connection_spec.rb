require 'spec_helper'

describe Connection do
  # test cardinality/connection type/protocols

  before(:all) do
    @from = Identity.create!({
      :uid => 'connection_spec_1',
      :name => 'test',
      :url => "http://www.google.com",
      :image => "http://www.google.com/favicon.ico",
      :context_name => 'facebook'
      })
    @to = Identity.create!({
      :uid => 'connection_spec_2',
      :name => 'test',
      :url => "http://www.google.com",
      :image => "http://www.google.com/favicon.ico",
      :context_name => 'facebook'
      })
    @friendcontext = ConnectionContext.find_by_name 'facebook-friendship'
    @likecontext = ConnectionContext.find_by_name 'facebook-like'
    @reccontext = ConnectionContext.find_by_name 'linkedinrecommendation-sp'
  end

  it "should create a valid connection" do
    connections = Connection.connections_with_context(@from, @to, @friendcontext)
    connections.count.should == 0
    Connection.create_with_context(@from, @to, @friendcontext)
    connections = Connection.connections_with_context(@from, @to, @friendcontext)
    connections.count.should == 1
  end

  it "should not create more than on based on cardinality" do
    Connection.create_with_context(@from, @to, @friendcontext)

    connections = Connection.connections_with_context(@from, @to, @friendcontext)
    Connection.create_with_context(@from, @to, @friendcontext)

    connections.count.should == 1
    connections = Connection.connections_with_context(@from, @to, @friendcontext)
    connections.count.should == 1
  end

  it "should not create connection based on connection_type mismatch" do
    Connection.create_with_context(@from, @to, @likecontext)
    connections = Connection.connections_with_context(@from, @to, @likecontext)
    connections.count.should == 0
  end

  it "should honor the id1 cardinality and async flag" do
    connections = Connection.connections_with_context(@from, @to, @reccontext)
    connections.count.should == 0
    Connection.create_with_context(@from, @to, @reccontext, {:id => '1', :text => 'test'})
    connections = Connection.connections_with_context(@from, @to, @reccontext)
    connections.count.should == 1
    Connection.create_with_context(@from, @to, @reccontext, {:id => '1', :text => 'test'})
    connections = Connection.connections_with_context(@from, @to, @reccontext)
    connections.count.should == 1
    Connection.create_with_context(@from, @to, @reccontext, {:id => '2', :text => 'test'})
    connections = Connection.connections_with_context(@from, @to, @reccontext)
    connections.count.should == 2
    Connection.connections_with_context(@from, @to, @reccontext).count == 0
  end


end
