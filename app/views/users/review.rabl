node :length do 
  1
end

node :nodes do |a|
  [
    partial('users/identity', :object => a.from),
    partial('users/identity', :object => a.to)
  ]
end

node :connections do |a|
  [partial('users/connection', :object => a)]
  end