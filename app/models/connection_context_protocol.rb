class ConnectionContextProtocol < ActiveRecord::Base
  attr_accessible :attribute_constraints, :context_constraints, :name
  store :attribute_constraints
  store :context_constraints

  has_and_belongs_to_many :connection_contexts
end
