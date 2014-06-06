class CreateConnectionContextProtocols < ActiveRecord::Migration
  def change
    create_table :connection_context_protocols do |t|
      t.string :name
      t.text :attribute_constraints
      t.text :context_constraints

      t.timestamps
    end
    add_index :connection_context_protocols, :name, :unique => true

    create_table :connection_context_protocols_connection_contexts, :id => false do |t|
      t.references :connection_context_protocol, :connection_context
    end

    add_index :connection_context_protocols_connection_contexts, [:connection_context_protocol_id, :connection_context_id], :name => :conntextion_context_protocol_implementors
  end
end
