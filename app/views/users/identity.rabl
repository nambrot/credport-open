cache
attribute :name, :url, :image

child :context => :context do
  extends 'users/identity_context'
end