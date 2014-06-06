cache
attribute :name, :url, :image
child :context => :context do
  extends 'users/entity_context'
end