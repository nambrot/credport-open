node :title do
  'Reviews'
end

node :type do
  'path-list'
end

node :data do |a|
  @user.reviews.map{ |review| partial('users/review', :object => review) }
end
