node :properties do |a|
  escape_objects a.properties
end
child :context => :context do
  extends 'users/connection_context'
end