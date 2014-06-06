require 'spec_helper'

describe ConnectionContext do
  it "should create a valid context" do
    context = ConnectionContext.create! :name => 'conconspeccontext', :application => Application.all.first, :async => true, :cardinality => '1', :connection_type => 'identity-identity'
  end

  it "should refuse to add an imcompatible protocol" do
    context = ConnectionContext.create! :name => 'conconspeccontext', :application => Application.all.first, :async => true, :cardinality => '1', :connection_type => 'identity-identity'
    context.connection_context_protocols.count.should == 0
    relprotocol = ConnectionContextProtocol.find_by_name 'relationship-protocol'
    begin
      context.connection_context_protocols << relprotocol
    rescue
    end
    context.connection_context_protocols.count.should == 0
    context.update_attribute(:properties, {:relationship => {
          :sourcerole => 'recommender',
          :sinkrole => 'recommendee'
        }})
    begin
      context.connection_context_protocols << relprotocol
    rescue
    end
    context.connection_context_protocols.count.should == 1
  end

end
