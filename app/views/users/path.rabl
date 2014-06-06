node do |a|
  {
    :length => a.length,
    :nodes => a.nodes.map{ |node| partial('users/identity', :object => node) },
    :connections => a.connections.map{ |connection| partial('users/connection', :object => connection) }
  }
end