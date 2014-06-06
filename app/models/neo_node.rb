module NeoNode

  def self.neo
    @neo = Neography::Rest.new( ENV['NEO4J_URL'] || "http://localhost:7474")
  end
  def self.included(base)
    base.after_create :save_to_neo
    base.extend ActiveModel::Callbacks
    base.attr_accessible :ignore_neo
    base.define_model_callbacks :create_neo4j_node
    base.after_destroy :delete_from_neo

    def base.neo
      @neo = Neography::Rest.new( ENV['NEO4J_URL'] || "http://localhost:7474")
    end

    def base.instantiate_from_neo4j(data, extra = {})
      return data['data']['type'].constantize.find(data['data']['id'])
    end

    def base.batch_create_neo4j_nodes(records)
      records.each_slice(100).map do |records|
        neo.batch *records.map { |record| [:create_unique_node, 'nodes_index', 'id', record.neo_id, record.node_attributes] }
      end
    end
    
    def base.batch_instantiate_from_neo4j(data)
      # data is now an array of arrays of nodes
      # first split them into their classes
      masterobject = {}
      data.flatten.each{ |node| masterobject[node['data']['type']] = [] unless masterobject.has_key?(node['data']['type']); masterobject[node['data']['type']] << node['data']['id'] }

      # master object now looks like {'identity' => [1,2,3,4], 'entity' => [1,2,3,4]}

      # fetch the records
      masterobject = masterobject.inject({}) do |oldhash, (type, idarray)|
        case type
        when 'Identity'
          oldhash[type] = Hash[*Identity.includes(:context => {:application => {:entity => :context}}).find(idarray).collect{|object| [object.id, object]}.flatten]
        when 'Entity'
          oldhash[type] = Hash[*Entity.includes(:context => {:application => {:entity => :context}}).find(idarray).collect{|object| [object.id, object]}.flatten]
        when 'Connection'
          oldhash[type] = Hash[*Connection.includes(:context => {:application => {:entity => :context}}).find(idarray).collect{|object| [object.id, object]}.flatten]
        end
        oldhash
      end
      # master object now looks like {'identity' => {1 => }}

      # now reconstruct the original records
      return data.map { |nodes| nodes.map { |node| masterobject[node['data']['type']][node['data']['id']] } }
    end
  end

  def ignore_neo=(value)
    @ignore_neo = value
  end

  def neo
    self.class.neo
  end

  def node_attributes
    {
      :type => self.class.to_s,
      :id => self.id
    }
  end

  def neo_id
    "#{self.class.to_s}#{self.id}"
  end

  def save_to_neo
    if @ignore_neo.nil? or !@ignore_neo
      run_callbacks :create_neo4j_node do
        node = neo.create_unique_node('nodes_index', 'id', neo_id, node_attributes)
        raise "Neo4j creation failed" unless node
      end
    end
  end

  def delete_from_neo
    if @ignore_neo.nil? or !@ignore_neo
      node = neo.get_node_index('nodes_index', 'id', neo_id).first
      raise "Neo4j deletion failed" unless node
      begin
      neo.remove_node_from_index('nodes_index', 'id', neo_id, node)
      neo.delete_node(node)
      rescue
        puts 'had to rescue'
      end
      
    end
  end


end