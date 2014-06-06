node :title do
  'Common Connections'
end

node :type do
  'path-list'
end

node :data do |a|
  @paths.map{ |path| partial('users/path', :object => path) }
end

node :user do
  api_v1_user_url(@user, :protocol => 'https')
end

node :pagination do
  @pagination
end