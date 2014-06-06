class ConnectionValidator < ActiveModel::Validator

  def validate(record)
    if !record.context
      record.errors[:context] << "can't be nil"
      return
    end

    if !record.persisted?
      record.errors[:from] << "is not persisted" unless record.from.persisted?
      record.errors[:to] << "is not persisted" unless record.to.persisted?
      record.errors[:context] << 'is not persisted' unless record.context.persisted?
      
      cardinalityerrors = self.class.validate_cardinality(record.from, record.to, record.context, record.properties)
      connection_typeerrors = self.class.validate_connection_type(record.from, record.to, record.context)
      constrainttypeerrors = self.class.validate_connection_context_protocols(record.from, record.to, record.context, record.properties)
      
      record.errors[:cardinality].push *cardinalityerrors unless cardinalityerrors.empty?
      record.errors[:connection_type].push *connection_typeerrors unless connection_typeerrors.empty?
      record.errors[:protocol_constraints].push *constrainttypeerrors unless constrainttypeerrors.empty?

    else
      # its already persisted, so check that endpoints havent changed
      record.errors[:from] << "must not change" if record.from_id_changed?
      record.errors[:to] << "must not change" if record.to_id_changed?
      record.errors[:context] << 'must not change' if record.context_id_changed?

      connection_typeerrors = self.class.validate_connection_type(record.from, record.to, record.context)
      constrainttypeerrors = self.class.validate_connection_context_protocols(record.from, record.to, record.context, record.properties)

      record.errors[:connection_type].push *connection_typeerrors unless connection_typeerrors.empty?
      record.errors[:protocol_constraints].push *constrainttypeerrors unless constrainttypeerrors.empty?
    end
  end

  def self.validate_cardinality(from, to, context, properties)
    valid = true
    if context.cardinality == '1'
      valid &&= !Connection.exists?(:from_id => from.id, :from_type => from.class.to_s, :to_id => to.id, :to_type => to.class.to_s, :context_id => context.id)
    end
    if context.cardinality == 'id1'
      valid &&= Connection.connections_with_context(from, to, context).all? { |connection| connection.properties[:id] != properties[:id] }
    end
    
    return ['is not valid. Connection already exists.'] unless valid
    return []
  end

  def self.validate_connection_type(from, to, context)
    errors = []
    case context.connection_type
    when 'identity-identity'
      errors << "does not match connection endpoints" unless from.class == to.class and to.class == Identity
    when 'identity-entity'
      errors << "does not match connection endpoints" unless from.class == Identity and to.class == Entity
    end
    errors
  end

  def self.validate_connection_context_protocols(from, to, context, properties, additional_protocols = [])
    errors = []
    begin
      context.connection_context_protocols.to_a.concat(additional_protocols).each{ |protocol| 
        protocol.attribute_constraints.each{ |(attribute_key, attribute_constraints)| 
          attribute_constraints.each{ |(constrainttype, value)| 
            case constrainttype
            when :presence
              raise "#{attribute_key} is not present" unless properties.has_key?(attribute_key)
            when :in
              raise "#{attribute_key} is not in #{value.to_json}" unless value.include?(properties[attribute_key])
            when :type
              value = value.to_sym
              case value
              when :string
                raise "#{attribute_key} is not a string" unless properties[attribute_key].class == String
              end
            end
          }
        }
      }
    rescue Exception => ex
      errors << "not fulfilled. #{ex.message}"
    end
    errors
  end

end