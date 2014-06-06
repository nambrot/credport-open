class MakeConnectionContextProtocolJoinTableUnique < ActiveRecord::Migration
  def change
    remove_index :connection_context_protocols_connection_contexts, :name => :conntextion_context_protocol_implementors
    add_index :connection_context_protocols_connection_contexts, [:connection_context_protocol_id, :connection_context_id], :name => :conntextion_context_protocol_implementors, :unique => true
  end
end
