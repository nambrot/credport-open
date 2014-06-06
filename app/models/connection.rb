class Connection < ActiveRecord::Base
  include NeoEdge

  PAGINATION_DEFAULT = 10;

  attr_accessible :properties, :from, :to, :context
  store :properties
  
  belongs_to :from, :polymorphic => true
  belongs_to :to, :polymorphic => true
  belongs_to :context, :class_name => 'ConnectionContext', :foreign_key => :context_id

  belongs_to :from_identity, :class_name => "Identity", :foreign_key => :from_id, :conditions => "from_type = 'Identity'"
  belongs_to :to_identity, :class_name => "Identity", :foreign_key => :to_id, :conditions => "to_type = 'Identity'"

  
  # validates_associated :from
  # validates_associated :to
  # validates_associated :context

  
  validates_with ConnectionValidator

  def self.validate_against_context(from, to, context, properties)
    valid = true
    # check cardinality
    if context.cardinality == '1'
      valid &&= !Connection.exists?(:from_id => from.id, :from_type => from.class.to_s, :to_id => to.id, :to_type => to.class.to_s, :context_id => context.id)
      valid &&= !Connection.exists?(:from_id => to.id, :from_type => to.class.to_s, :to_id => from.id, :to_type => from.class.to_s, :context_id => context.id) unless context.async
    end
    
    return valid unless valid

    if context.cardinality == 'id1'
      valid &&= Connection.connections_with_context(from, to, context).all? { |connection| connection.properties[:id] != properties[:id] }
    end
    return valid unless valid

    # check connection type
    case context.connection_type
    when 'identity-identity'
      valid &&= from.class == to.class and to.class == Identity
    when 'identity-entity'
      valid &&= from.class == Identity and to.class == Entity
    end

    return valid unless valid
    
    # check whether we fulfill protocols on the context
    begin
      context.connection_context_protocols.each{ |protocol| 
        protocol.attribute_constraints.each{ |(attribute_key, attribute_constraints)| 
          attribute_constraints.each{ |(constrainttype, value)| 
            case constrainttype
            when :presence
              raise "#{attribute_key} is not present" unless properties.has_key?(attribute_key)
            when :in
              raise "#{attribute_key} is not in #{value.to_json}" unless value.include?(properties[attribute_key])
            when :type
              case value
              when :string
                raise "#{properties[attribute_key]} is not a string" unless properties[attribute_key].class == String
              end
            end
          }
        }
      }
    rescue 
      valid &&= false
    end

    return valid
  end

  def node_attributes
    super.merge({
      :context_name => context.name
    })
  end

  def self.create_with_context!(from, to, context, properties = {})
    con = nil
    Connection.transaction do
      raise "Record is invalid!" unless validate_against_context(from, to, context, properties)
      if context.async
        con = Connection.create!(:from => from, :to => to, :context => context, :properties => properties)
      else
        con = Connection.create!(:from => from, :to => to, :context => context, :properties => properties)
        Connection.create!(:from => to, :to => from, :context => context, :properties => properties)
      end
    end
    con
  end

  def self.create_with_context(from, to, context, properties = {})
    begin
      self.create_with_context!(from, to, context, properties)
    rescue Exception => e
      Connection.create(:from => from, :to => to, :context => context, :properties => properties)
    end
  end

  def self.stats_without_viewer(to)
    return {
      :reviews => to.reviews.count,
      :common_connections => 0,
      :common_interests => 0,
      :degree_of_seperation => 0,
      :accounts => to.identities.count - 1,
      :verifications => to.emails.count + to.phones.count + to.websites.count
    }
  end

  def self.stats_with_viewer(from, to)
    batchcall = neo.batch [
      :execute_query,
      "START from_user = node:nodes_index(id = {from}), to_user = node:nodes_index(id = {to})
      MATCH from_user-[:identity]->from_identity
      WITH from_identity, to_user
      MATCH to_user-[:identity]->to_identity
      WITH from_identity, to_identity
      MATCH from_identity -[from_connection:connection]-> common_connection -[to_connection:connection]-> to_identity
      RETURN count(common_connection)
       ", {
       :from => from.neo_id,
       :to => to.neo_id
     }
    ], [
      :execute_query,
      " START from_user = node:nodes_index(id = {from}), to_user = node:nodes_index(id = {to})
      MATCH from_user-[:identity]->from_identity
      WITH from_identity, to_user
      MATCH to_user-[:identity]->to_identity
      WITH from_identity, to_identity
      MATCH from_identity -[from_connection:connection]-> common_interest <-[to_connection:connection]- to_identity
      WHERE not( from_identity -[from_connection:connection]-> common_interest -[:connection]-> to_identity )
      RETURN count(common_interest)
      ", {
      :from => from.neo_id,
      :to => to.neo_id
    }
    ], [
      :execute_query,
      " START from_user = node:nodes_index(id = {from}), to_user = node:nodes_index(id = {to})
      MATCH from_user-[:identity]->from_identity
      WITH from_identity, to_user
      MATCH to_user-[:identity]->to_identity
      WITH from_identity, to_identity
      MATCH path= shortestPath( from_identity-[:connection*..4]->to_identity )
      RETURN length(path)
      ORDER BY length(path)
      ", {
      :from => from.neo_id,
      :to => to.neo_id
    }
    ]

    batchcall.map!{|node| node['body']['data'].first.nil? ? 0 : node['body']['data'].first.first}

    return {
      :reviews => to.reviews.count,
      :common_connections => batchcall[0],
      :common_interests => batchcall[1],
      :degree_of_seperation => batchcall[2],
      :accounts => to.identities.count - 1,
      :verifications => to.emails.count + to.phones.count + to.websites.count
    }
  end

  def self.common_connections(from, to, page=1, per_page=PAGINATION_DEFAULT)
    # TODO: make this more efficient
    page = 1 if page.nil?
    per_page = PAGINATION_DEFAULT if per_page.nil?

    begintime = Time.now
    data = neo.execute_query("
      START from_user = node:nodes_index(id = {from}), to_user = node:nodes_index(id = {to})
      MATCH from_user-[:identity]->from_identity
      WITH from_identity, to_user
      MATCH to_user-[:identity]->to_identity
      WITH from_identity, to_identity
      MATCH from_identity -[from_connection:connection]-> common_connection -[to_connection:connection]-> to_identity
      RETURN from_identity, from_connection, common_connection, to_connection, to_identity
      SKIP {s}
      LIMIT {l};
      ",{
      :from => from.neo_id,
      :to => to.neo_id,
      :s => (page-1) * per_page, 
      :l => per_page
      })['data']

      ap "neo4j sc #{Time.now - begintime}"
      Identity.batch_instantiate_from_neo4j(data).map{|rawpath| Path.new rawpath}
  end

  def self.common_interests(from, to, page=1, per_page=PAGINATION_DEFAULT)
    page = 1 if page.nil?
    per_page = PAGINATION_DEFAULT if per_page.nil?
    begintime = Time.now
    data = neo.execute_query("
      START from_user = node:nodes_index(id = {from}), to_user = node:nodes_index(id = {to})
      MATCH from_user-[:identity]->from_identity
      WITH from_identity, to_user
      MATCH to_user-[:identity]->to_identity
      WITH from_identity, to_identity
      MATCH from_identity -[from_connection:connection]-> common_interest <-[to_connection:connection]- to_identity
      WHERE not( from_identity -[from_connection:connection]-> common_interest -[:connection]-> to_identity )
      RETURN from_identity, from_connection, common_interest, to_connection, to_identity
      SKIP {s}
      LIMIT {l};
      ",{
      :from => from.neo_id,
      :to => to.neo_id,
      :s => (page-1) * per_page, 
      :l => per_page
      })['data']

      ap "neo4j ci #{Time.now - begintime}"
      Identity.batch_instantiate_from_neo4j(data).map{|rawpath| Path.new rawpath}
  end

  def self.connections_with_context(from, to, context)
    Connection.where :from_id => from.id, :from_type => from.class.to_s, :to_id => to.id, :to_type => to.class.to_s, :context_id => context.id
  end

  def serializable_hash(options = {})
    options = { 
      :include => [:from, :to, :context], 
      :only => [:properties]
    }.update(options)
    super(options)
  end
end
