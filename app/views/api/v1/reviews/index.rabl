object false
child @reviews => :data do
  extends 'users/review'
end

node :title do
  'Reviews'
end

node :type do
  'path-list'
end

node :pagination do
  @pagination
end