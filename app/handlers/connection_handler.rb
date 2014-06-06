class ConnectionHandler
 
  # Returns the Queue the ConnectionHandler is bound to
  def self.queue
    return @queue.to_s
  end

  @queue = :auth_queue
  
  # Worker's perform method. Given a the uid and provider
  # the user is found and respective API is called to process there connections
  def self.perform( credentials , uid, context_name)
    puts "Delayed Job Triggered for #{uid}:#{context_name}" 
    # Extract the user tp from the uid and provider and pass to the respective api
    identity = Identity.find_by_uid_and_context_name(uid, context_name)

    if identity.nil?
      puts "Could not find Identity with #{uid}:#{context_name}"
      return
    end

    case context_name
    when 'facebook'
      FacebookAPI.new(credentials, identity).get_connections
    when 'linkedin'
      LinkedinAPI.new(credentials, identity).get_connections
    when 'twitter'
      TwitterAPI.new(credentials, identity).get_connections
    when 'ebay'
      EbayAPI.new( credentials, identity).get_connections
    when 'xing'
      XingAPI.new(credentials, identity).get_connections
    end

    puts "Delayed Job Completed Task #{uid}:#{context_name}"
  end

  def self.build_user_object_connections(connections, identity)

    context = ConnectionContext.find_by_name(connections[:context][:name])
    raise "Couldn't find appropriate context" unless context
    for connection in connections[:connections]
      entity = Entity.find_or_create(connection[:entity])
      if connection[:connection][:from] == 'me'
        Connection.create_with_context(identity, entity, context, connection[:connection][:properties])
      else
        Connection.create_with_context(entity, identity, context, connection[:connection][:properties])
      end
    end
  end

  def self.build_user_user_connections(connections, identity)
    context = ConnectionContext.find_by_name(connections[:context][:name])
    raise "Couldn't find appropriate context" unless context

    # Batch that shit
    # batch create identities
    identities = Identity.batch_find_or_create(connections[:connections].map{|a| a[:identity]})

    connections[:connections] = connections[:connections].zip(identities).map { |(hash, identity)| hash[:identity] = identity; hash; }

    for connection in connections[:connections]
      if connection[:connection][:from] == 'me'
        Connection.create_with_context(identity, connection[:identity], context, connection[:connection][:properties])
      else
        Connection.create_with_context(connection[:identity], identity, context, connection[:connection][:properties])
      end
    end
  end

  # Returns a new Countdown with the counter set to argument n
  def self.countdown(n)
    return Countdown.new(n)
  end

  class Countdown
    def initialize( n )
      @count = n
    end

    def minus_one
      @count -= 1
    end

    def count
      @count
    end      
    
    def add (n)
      @count += n
    end
  end

end
