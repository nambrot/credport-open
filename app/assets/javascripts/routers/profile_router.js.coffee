class @ProfileRouter extends Backbone.Router
	initialize: (options) ->
	# Routing Stuff
	routes: 
		'u/:id': 'routeProfile'
		'u/:id/education': 'routeEducation'
		'u/:id/work': 'routeWork'
		'u/:id/edit': 'routeEdit'
		'u/:id/commonconnections': 'routeCommonConnections'
		'u/:id/commoninterests': 'routeCommonInterests'
		'u/:id/requestRecommendations': 'routeRecommendationRequest'
		'u/:id/writeRecommendation': 'routeRecommendationNew'
		'u/:id/reviews': 'routeReviews'
		'u/:id/signup': 'routeSignup'
	routeEducation: ->
		@trigger 'education_overlay'
	routeWork: ->
		@trigger 'work_overlay'
	routeEdit: ->
		@trigger 'edit_overlay'
	routeProfile: ->
		@trigger 'edit_off'
	routeCommonConnections: ->
		@trigger 'commonconnections_overlay'
	routeCommonInterests: ->
		@trigger 'commoninterests_overlay'
	routeReviews: ->
		@trigger 'review_overlay'
	routeRecommendationRequest: ->
		@trigger 'recommendation_request_overlay'
	routeRecommendationNew: ->
		@trigger 'recommendation_new_overlay'
	routeSignup: ->
		@trigger 'signup_overlay'