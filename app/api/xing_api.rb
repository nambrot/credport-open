require 'em-http/middleware/oauth'

# An API for interfacing with XING
# using event machine for async calls
class XingAPI

  def initialize( credentials, identity, current_user=nil)
    @credentials = credentials
    @context_name = identity.context.name
    @current_user = current_user
    @token = credentials[:token]
    @secret = credentials[:secret]
    @identity = identity
    @total_contacts = identity.properties[:total_contacts].to_i
    
    @xing_id = identity.uid
    @xing_batch_size = 99
    @xing_url = "https://api.xing.com/v1/"
    @oauth_config = { 
      :consumer_key => Rails.configuration.api_keys['xing']['key'],
      :consumer_secret => Rails.configuration.api_keys['xing']['secret'],
      :access_token => @token,
      :access_token_secret => @secret
      }
      
  end

  def get_connections
    
    @connections_buffer = []

    @countdown = ConnectionHandler.countdown( @total_contacts/@xing_batch_size + 1 );
    
    EventMachine.run do
      (0..@total_contacts).to_a.each_slice(@xing_batch_size).each{|range| dispatch_connections(range.first) }
    end

    connection_data = {:context => ContactContext, :connections=> @connections_buffer}

    if (Rails.env != "production")
      Rails.logger.debug "DEBUG dumping json outputs to tmp/folder"
      File.open( "tmp/xing_contacts.json","w"){|f| f.write(connection_data.to_json) }
    end

    Rails.logger.info "INFO Writing XING Contacts"
    ConnectionHandler.build_user_user_connections( connection_data , @identity )

  end

  def dispatch_connections( offset = 0 ,  tries = 0 )
    request = EventMachine::HttpRequest.new(@xing_url+ "users/me/contacts?"+parameters(offset))
    request.use EventMachine::Middleware::OAuth, @oauth_config

    http = request.get

    http.callback do
      if http.response_header.status != 200 and http.response_header.status != 302 
        Rails.logger.fatal "Xing Connection failed with Error Code #{http.response_header.status}"
        Rails.logger.ap http
        raise "Unexpected response status #{http}"
      end

      begin
        contacts = MultiJson.decode(http.response)["contacts"]["users"]
        connection_info = contacts.map{|data| data.deep_symbolize_keys }.keep_if{ |connection| connection.has_key?(:photo_urls)}.map{ |connection| 
          {
            :identity => {
              :uid => connection[:id],
              :context_name => :xing,
              :credentials => {},
              :name => connection[:display_name],
              :image => connection[:photo_urls][:large],
              :url => connection[:permalink],
              :properties => get_headline(connection)
            },
            :email => connection.has_key?(:active_email)?connection[:active_email]:nil,
            :connection => {
              :from => "me",
              :to => "you",
              :properties => {}
            }
          }
        }
        @connections_buffer.concat( connection_info )
        Rails.logger.info "Xing Connectino Dispatch Successful Countdown: #{@countdown.count}"
      rescue Exception => ex
        Rails.logger.fatal "FATAL : Xing Parse Error #{ex.message}"
        Rails.logger.fatal "FATAL : Xing Parse Error Backtrace ... "
        ex.backtrace[0..10].each{|trace| Rails.logger.fatal trace}
        Rails.logger.fatal "XING Connection Dispath Bad Responnse #{@countdawn.count}"
        Rails.logger.ap http.response
      ensure
        stop_if_finished
      end
    end

    http.errback do
      if tries <= 3 
        Rails.logger.warn "Xing Fetch Connection Request #{@countdown.count} Errored, Trying Again"
        dispatch_connections( offset ,tries+1)
      else
        Rails.logger.fatal "Xing Fetch Connection Request #{@countdown.count} Failed, Giving up"
        stop_if_finished
      end
    end
  end

  def get_headline( connection )
    if connection.has_key?(:professional_experience)
      if connection[:professional_experience].has_key?(:primary_company)
       title = connection[:professional_experience][:primary_company][:title]
       name = connection[:professional_experience][:primary_company][:name]
        if title and name
          return {"Headline" => "#{title} at #{name}"} 
        end
      end
    end
    return {}
  end

  def parameters( offset )
    "offset=#{offset}&limit=#{@xing_batch_size}&user_fields=id,display_name,photo_urls.large,professional_experience.primary_company.name,professional_experience.primary_company.title,permalink,active_email"
  end

  def stop_if_finished
    EM.stop if @countdown.minus_one == 0
  end

  ContactContext = { :name => 'xing-connection' } 
end
