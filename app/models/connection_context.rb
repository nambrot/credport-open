class ConnectionContext < ActiveRecord::Base
  attr_accessible :async, :cardinality, :connection_type, :name, :properties, :application

  store :properties

  validates :name, :presence => true, :uniqueness => true
  validates :async,
    :inclusion => { :in => [true, false] }
  validates :cardinality,
    :inclusion => { :in => ['1', 'id1'] },
    :presence => true
  validates :connection_type,
    :inclusion => { :in => ['identity-identity', 'identity-entity'] },
    :presence => true
  belongs_to :application
  validates_associated :application
  
  has_many :connections,  :foreign_key => :context_id
  has_and_belongs_to_many :connection_context_protocols, :before_add => :validate_protocol_constraints, :uniq => true

  before_save :validate_context_attributes

  def validate_context_attributes
    connection_context_protocols.each{ |protocol| 
      validate_protocol_constraints protocol
    }

    # check the connections
    Connection.where(:context_id => self.id).each do |connection|
      if self.cardinality_changed?
        raise "Connection is not valid" unless ConnectionValidator.validate_cardinality(connection.from, connection.to, self, connection.properties).empty?
      end
      if self.connection_type_changed?
        raise "Connection is not valid" unless ConnectionValidator.validate_connection_type(connection.from, connection.to, self).empty?
      end
    end
  end

  def validate_protocol_constraints(protocol)
    validate_attributes!(protocol.context_constraints, properties)
    Connection.where(:context_id => self.id).each do |connection|
      raise "Connection is not valid" unless ConnectionValidator.validate_connection_context_protocols(connection.from, connection.to, self, connection.properties, [protocol]).empty?
    end
  end

  def validate_attributes!(constraints, attributes)
    constraints.each{ |(attribute_key, attribute_constraints)|
      attribute_constraints.each{ |(constrainttype, value)| 
        case constrainttype
        when :presence
          raise "#{attribute_key} is not present" unless attributes.has_key?(attribute_key)
        when :in
          raise "#{attribute_key} is not in #{value.to_json}" unless value.include?(attributes[attribute_key])
        when :type
          case value
          when :string
            raise "#{attributes[attribute_key]} is not a string" unless attributes[attribute_key].class == String
          when :hash
            raise "#{attributes[attribute_key]} is not a Hash" unless attributes[attribute_key].class == Hash
          end
        when :format
          validate_attributes!(value, attributes[attribute_key])
        end
      }
    }
  end

  def serializable_hash(options = {})
    options = {  
      :only => [:properties, :name, :async, :cardinality]
    }.update(options)
    super(options)
  end
end
