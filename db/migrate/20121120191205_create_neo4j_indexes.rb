class CreateNeo4jIndexes < ActiveRecord::Migration
  def up
    Identity.neo.create_node_index('nodes_index')
    Identity.neo.create_relationship_index('edges_index')
  end

  def down
    Identity.neo.connection.delete(Neography::Rest::NodeIndexes.new(Identity.neo.connection).base_path(:index => 'nodes_index'))
    Identity.neo.connection.delete(Neography::Rest::RelationshipIndexes.new(Identity.neo.connection).base_path(:index => 'edges_index'))
  end
end
