cache
attributes :name, :async, :cardinality, :connection_type
node :properties do |a|
  escape_objects a.properties
end
node :application do |context|
  partial 'users/entity_limited', :object => context.application.entity
end