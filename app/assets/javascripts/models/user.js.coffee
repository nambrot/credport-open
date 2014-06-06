# = require models/stats
class @User extends Backbone.Model
	urlRoot: '/api/v1/users'
	first_name: ->
		@get('name').split(' ')[0]
	parse: (resp, xhr) ->
		resp.user
	verifications: (callback) ->
		if !@verificationsobject?
			@verificationsobject = new VerificationCollection(@get('verifications').identities.concat(@get('verifications').real) || [])
			@verificationsobject.user = this
		callback @verificationsobject
	work: (callback) ->
		if !@workobject?
			@workobject = new WorkHistory(@get('work') || [])
			@workobject.user = this
		callback @workobject
	education: (callback) ->
		if !@educationobject?
			@educationobject = new EducationHistory(@get('education') || [])
			@educationobject.user = this
		callback @educationobject
	reviews: (callback) ->
		if !@reviewsobject?
			@reviewsobject = new Reviews(@get('reviews') || [])
			@reviewsobject.user = this
		callback @reviewsobject if callback?
		@reviewsobject
	recommendations_to_approve: (callback) ->
		if !@recommendations_to_approve_object?
			@recommendations_to_approve_object = new Recommendations [], user: this
			@recommendations_to_approve_object.url = '/me/recommendations_to_approve.json'
			@recommendations_to_approve_object.on 'reset', (evt) =>
				if @recommendations_to_approve_object.length > 0
					mixpanel.track "Profile:RecommendationsToApprove:Yes", { length: @recommendations_to_approve_object.length, user: @get('id') }
					mixpanel.people.increment "Profile:RecommendationsToApprove:Yes"
				else
					mixpanel.track "Profile:RecommendationsToApprove:No", { user: @get('id') }
					mixpanel.people.increment "Profile:RecommendationsToApprove:No"
				callback @recommendations_to_approve_object if callback?
			@recommendations_to_approve_object.fetch()
		else
			callback @recommendations_to_approve_object if callback?
		@recommendations_to_approve_object
	commonconnections: (callback) ->
		if !@commonconnectionsobject?
			@commonconnectionsobject = new CommonConnections()
			@commonconnectionsobject.user = this
			@commonconnectionsobject.url = @url() + '/commonconnections/'
			@commonconnectionsobject.on 'reset', (evt) =>
				if @commonconnectionsobject.length > 0
					mixpanel.track "Profile:CommonConnections:Yes", { length: @commonconnectionsobject.length, user: @get('id') }
					mixpanel.people.increment "Profile:CommonConnections:Yes"
				else
					mixpanel.track "Profile:CommonConnections:No", { user: @get('id') }
					mixpanel.people.increment "Profile:CommonConnections:No"
				callback @commonconnectionsobject
			@commonconnectionsobject.fetch()
		else
			callback @commonconnectionsobject
	commoninterests: (callback) ->
		if !@commoninterestsobject?
			@commoninterestsobject = new CommonInterests()
			@commoninterestsobject.user = this
			@commoninterestsobject.url = @url() + '/commoninterests/'
			@commoninterestsobject.on 'reset', (evt) =>
				if @commoninterestsobject.length > 0
					mixpanel.people.increment "Profile:CommonInterests:Yes"
					mixpanel.track "Profile:CommonInterests:Yes", { length: @commoninterestsobject.length, user: @get('id') }
				else
					mixpanel.people.increment "Profile:CommonInterests:No"
					mixpanel.track "Profile:Commoninterests:No", { user: @get('id') }
				callback @commoninterestsobject
			@commoninterestsobject.fetch()
		else
			callback @commoninterestsobject
	stats: (callback) ->
		if !@statsobject?
			@statsobject = new Stats()
			@statsobject.user = this
			@statsobject.url = @url() + '/stats'
			@statsobject.on 'change', (evt) =>
				callback @statsobject
			@statsobject.fetch()
		else
			callback @statsobject
