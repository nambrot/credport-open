namespace :twitter do

	desc "Pass A Twitter ID and this will strip all connections and refetch them"
	task :strip_and_refetch, [:id]  => :environment  do |task, args|
		begin
			id = args[:id].to_i
			twitter = Identity.find(id)
			raise "No Credentials" if twitter.credentials.empty?
			
			incoming = Connection.where(:context_id => 3 , :to_id =>id )
			outgoing = Connection.where(:context_id => 3 , :from_id =>id )
			
			ap "We Have #{incoming.length} incoming connections"
			ap "We Have #{outgoing.length} outgoing connections"
			
			ap "Destroying incoming connections ... "
			incoming.each{|con| con.destroy}
			updated_incoming = Connection.where(:context_id => 3 , :to_id =>id )
			if updated_incoming.length == 0
			  ap "Successfully Destroyed incoming connections ... ", options ={:color => {:string =>:greenish }}
			else 
			  ap "WARNING after destruction we still have residual incoming connections", options = {:color => {:string => :redish }}
			end
			
			ap "Destroying outgoing connections ... "
			outgoing.each{|con| con.destroy}
			updated_outgoing = Connection.where(:context_id => 3 , :from_id =>id )
			if updated_incoming.length == 0
			  ap "Successfully Destroyed outgoing connections ... "	, options = {:color => {:string => :greenish }}
			else 
			  ap "WARNING after destruction we still have residual outgoing connections" , options = {:color => {:string => :redish }}

			end
			ap "STRIP SUCCESSFUL!" , options = {:color => {:string => :greenish }}


			ap "REFETCH BEGINING"
			twitter.fetch_connections(twitter.credentials)
			ap "REFETCH ENDED", options = {:color => {:string => :greenish }}

		
		rescue Exception => ex
			ap ex.message
		end
			
	end
end
