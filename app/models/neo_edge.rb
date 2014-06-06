module NeoEdge
  
  def self.neo
    @neo = Neography::Rest.new( ENV['NEO4J_URL'] || "http://localhost:7474")
  end
  def self.included(base)
    base.after_create :save_to_neo
    base.attr_accessible :neo_id
    base.after_destroy :delete_from_neo

    base.extend ActiveModel::Callbacks
    base.define_model_callbacks :create_neo4j_edge
    base.define_model_callbacks :delete_neo4j_edge 
    def base.neo
      @neo = Neography::Rest.new( ENV['NEO4J_URL'] || "http://localhost:7474")
    end

    def base.instantiate_from_neo4j(data, extra = {})
      return data['data']['type'].constantize.find(data['data']['id'])
    end
  end

  def neo
    self.class.neo
  end

  def edge_attributes
    {
      :type => self.class.to_s,
      :id => self.id,
      :context_id => self.context.id
    }
  end

  def save_to_neo
    run_callbacks :create_neo4j_edge do
      relationship = neo.execute_query("
        START from = node:nodes_index(id={from}), to = node:nodes_index(id = {to})
        CREATE from -[x:connection {type: {type}, id: {id}, context_id: {context_id}} ]-> to
        RETURN x;
        ", {
        :from => from.neo_id,
        :to => to.neo_id,
        :type => self.class.to_s,
        :id => self.id,
        :context_id => self.context.id
        })
      raise "Could not persist Relationship in Neo4j" unless relationship and relationship['data'] and relationship['data'].length > 0
    end
  end

  def delete_from_neo
    run_callbacks :delete_neo4j_edge do
      relationship = neo.execute_query("
        START from = node:nodes_index(id={from}), to = node:nodes_index(id = {to})
        MATCH from -[x:connection]-> to
        WHERE (x.id! = {id}) AND (x.context_id! = {context_id})
        DELETE x
        RETURN from, to;
        ", {
        :from => from.neo_id,
        :to => to.neo_id,
        :id => self.id,
        :context_id => self.context.id
        })
      # raise "Could not persist Relationship in Neo4j" unless relationship and relationship['data'] and relationship['data'].length > 0
    end
  end

end
