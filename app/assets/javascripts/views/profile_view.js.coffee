# = require jquery
# = require jquery_ujs
# = require backbone-rails
# = require gritter
# = require clamp
# = require models/misc
# = require models/user
# = require views/verification_views
# = require views/box_views
# = require views/connection_views
# = require views/education_views
# = require views/work_views
# = require views/review_views
# = require views/newuseroverlay
# = require views/user_canvas_overlay
# = require views/sidebar_views
# = require views/stats_view
# = require views/sign_up_views
# = require views/edit_overlay_view
# = require views/recommendation_views

class @ProfileView extends Backbone.View
	id: 'user-container'
	allowEditFlag: false
	editMode: false
	overlayed: false
	usercanvas: null
	initialize: (options) =>
		@router = options.router
		@current_user = options.current_user
		@allowEditFlag = options.allowEdit
		
		# register all the overlay events
		@router.on 'work_overlay', =>
			@renderWorkOverlay()
		@router.on 'education_overlay', =>
			@renderEducationOverlay()
		@router.on 'commonconnections_overlay', =>
			@renderCommonConnectionsOverlay()
		@router.on 'commoninterests_overlay', =>
			@renderCommonInterestsOverlay()
		@router.on 'review_overlay', @renderReviewsOverlay, this
		@router.on 'signup_overlay', @renderSignupOverlay, this
		@router.on 'edit_overlay', @renderEditOverlay, this
		@router.on 'recommendation_request_overlay', @renderRecommendationsRequestOverlay, this
		@router.on 'recommendation_new_overlay', @renderRecommendationsWriteOverlay, this
		
	# render stuff
	render: ->
		@$el.html("
			<div id='user-sidebar'>
			<div class='name'></div>
			<div class='tagline'></div>
			<div class='profilepic'></div>
			<div id='editcontainer'><a href='/u/#{@model.get('id')}/edit' class='button'>#{I18n.t('edit.your_profile')}</a></div>
			</div>
			<div id='user-stats-view'>
			</div>
			<div id='user-canvas'>
			</div>")

		@usercanvas = @$ '#user-canvas'
		@usersidebar = @$ "#user-sidebar"
		@userstats = @$ '#user-stats-view'

		if @allowEditFlag
			@usersidebar
				.addClass('allowEdit')
				.find('#editcontainer a')
				.css('display', 'inline')
				.on('click', null ,{}, =>
						@navigateEdit()
						return false;)
		# render the first stuff
		@model.stats (stats) =>
			view = new StatsView model: stats, el: @userstats, parentView: this
			view.on 'route', (route, trigger = true) =>
				@triggerRoute route, trigger
			view.render()
			view.$el.insertAfter @usersidebar
		@model.verifications (verifications) =>
			view = new VerificationCollectionView model: verifications
			view.render()
			view.on 'route', (route, trigger = true) =>
				@triggerRoute route, trigger
			@usersidebar.append view.el

		nameview = new ProfileNameView model: @model, el: @usersidebar.find('.name'), parent: this
		nameview.render()
		
		taglineview = new ProfileTaglineView model: @model, el: @usersidebar.find('.tagline'), parent: this
		taglineview.render()

		profilepicview = new ProfilePicView model: @model, el: @usersidebar.find('.profilepic'), parent: this
		profilepicview.render()

		if @allowEditFlag
			view = new RecommendationsBoxView model: @model
			view.on 'open', @navigateRecommendationRequest, this
			@usercanvas.append view.el
			
		# render the boxes
		@renderGenericBox _.bind(@model.reviews, @model), ReviewsBoxView, @navigateReviews
		@renderGenericBox _.bind(@model.work, @model), WorkBoxView, @navigateWork
		@renderGenericBox _.bind(@model.education, @model), EducationBoxView, @navigateEducation
		@renderGenericBox _.bind(@model.commonconnections, @model), CommonConnectionsBoxView, @navigateCommonConnections
		@renderGenericBox _.bind(@model.commoninterests, @model), CommonInterestsBoxView, @navigateCommonInterests
		
		if !@current_user?
			@model.commonconnections (connections) =>
				if connections.models.length == 0
					view = new SignUpBoxView model: @model
					view.on 'open', @navigateSignUp, this
					view.render()
					@usercanvas.append view.el
					setTimeout (=>
						view.$el.addClass 'show'
						),1

		this

	renderGenericBox: (userfunction, boxview, openfunction, ignore_collection = false) ->
		userfunction (collection) =>
			# don't render if its empty
			return if collection.models.length == 0 unless ignore_collection
			
			view = new boxview model: collection
			# binding open
			view.on 'open', =>
				openfunction.call(this)
			# render
			view.render()
			
			@usercanvas.append view.el
			setTimeout (=>
				view.$el.addClass 'show'
				),1
			
			view.startCycle()

	# overlays
	prepare_overlay:(verification_overlay=false) ->
		if !@overlayed? or !@overlayed
			# set up the overlay
			@dimmer = new UserCanvasOverlayDimmer()
			@dimmer.render()
			@overlay = new UserCanvasOverlay()
			@overlay.render()
			if verification_overlay
				@overlay.el.classList.add "verification-canvas"
			@$el.append @dimmer.el
			@$el.append @overlay.el

			# # set width
			# @overlay.css('max-width',$('#user-canvas').width())
			# $(window).resize =>
			# 	@overlay.css('max-width',$('#user-canvas').width())
			# @$el.append(@overlay)
			@overlayed = true
			# # modify the canvas
			@usercanvas.addClass('overlay')
			@userstats.addClass 'overlay'
			@overlay.on 'close', @clear_overlay, this
			@dimmer.on 'close', @clear_overlay, this
			# # event is still propagating
			# setTimeout ( => 
			# 	$(document).on 'keydown', null, {}, (evt) =>
			# 		@clear_overlay() if evt.which == 27
			# 	$(document).on 'click', null, {}, (evt) =>
			# 		@clear_overlay()
			# 	$(document).on 'click', '#user-canvas-overlay', {}, (evt) =>
			# 		evt.stopPropagation()
			# ), 1
	clear_overlay: ->
		if @allowEditFlag && @editMode
			@triggerRoute "/u/#{@model.get('id')}/edit"
		else
			@triggerRoute "/u/#{@model.get('id')}"
		@overlayed = false
		$('#user-canvas').removeClass('overlay')
		@userstats.removeClass 'overlay'
		if @overlay?
			mixpanel.track("Profile:Overlay:Remove")
			@overlay.remove()
			@dimmer.remove()
			@overlay = null
			
	renderWorkOverlay: ->
		@clear_overlay() if @overlayed
		@prepare_overlay()
		@model.work (work) =>
			view = new WorkDetailView model: work
			view.on 'removeOverlay', @clear_overlay, this
			view.render()
			@overlay.addSubview(view)
		mixpanel.track("Profile:WorkOverlay:Open")
	renderEducationOverlay: ->
		@clear_overlay() if @overlayed
		@prepare_overlay()
		@model.education (education) =>
			view = new EducationDetailView model: education
			view.on 'removeOverlay', @clear_overlay, this
			view.render()
			@overlay.addSubview(view)
		mixpanel.track("Profile:EducationOverlay:Open")
	renderCommonConnectionsOverlay: ->
		@clear_overlay() if @overlayed
		@prepare_overlay()
		@model.commonconnections (commonconnections) =>
			view = new CommonConnectionsDetailView model: commonconnections
			view.on 'removeOverlay', @clear_overlay, this
			view.render()
			@overlay.addSubview(view)
		mixpanel.track("Profile:CommonConnectionsOverlay:Open")
	renderCommonInterestsOverlay: ->
		@clear_overlay() if @overlayed
		@prepare_overlay()
		@model.commoninterests (commoninterests) =>
			view = new CommonInterestsDetailView model: commoninterests
			view.on 'removeOverlay', @clear_overlay, this
			view.render()
			@overlay.addSubview(view)
		mixpanel.track("Profile:CommonInterests:Open")
	renderReviewsOverlay: ->
		@clear_overlay() if @overlayed
		@prepare_overlay()
		@model.reviews (reviews) =>
			view = new ReviewsOverlayView model: reviews
			view.on 'removeOverlay', @clear_overlay, this
			view.render()
			@overlay.addSubview(view)
		mixpanel.track("Profile:ReviewOverlay:Open")
	renderSignupOverlay: ->
		@clear_overlay() if @overlayed
		@prepare_overlay()
		view = new SignupOverlayView model: @model
		view.on 'removeOverlay', @clear_overlay, this
		view.render()
		@overlay.addSubview(view)
		mixpanel.track("Profile:SignUpOverlay:Open")
	renderEditOverlay: ->
		if @allowEditFlag
			@clear_overlay() if @overlayed
			@prepare_overlay()
			view = new EditOverlayView model: @model
			view.on 'removeOverlay', @clear_overlay, this
			view.render()
			@overlay.addSubview(view)
			mixpanel.track("Profile:EditOverlay:Open")
		else
			$.gritter.add
				title: I18n.t("Error")
				text: I18n.t("This is not your profile")
			@triggerRoute "/u/#{@model.get('id')}"
	renderRecommendationsRequestOverlay: ->
		if @allowEditFlag
			@clear_overlay() if @overlayed
			@prepare_overlay()
			view = new RecommendationRequestOverlayView model: @model
			view.on 'removeOverlay', @clear_overlay, this
			view.render()
			@overlay.addSubview(view)
			mixpanel.track("Profile:RecommendationsRequestOverlay:Open")
		else
			$.gritter.add
				title: I18n.t("Error")
				text: I18n.t("This is not your profile")
			@triggerRoute "/u/#{@model.get('id')}"
	renderRecommendationsWriteOverlay: ->
		if !@current_user? or @model.get('id') != @current_user.id
			@clear_overlay() if @overlayed
			@prepare_overlay()
			view = new RecommendationWriteOverlayView model: @model, current_user: @current_user
			view.on 'removeOverlay', @clear_overlay, this
			view.render()
			@overlay.addSubview(view)
			mixpanel.track("Profile:RecommendationWriteOverlay:Open")
		else
			$.gritter.add
				title: I18n.t("Error")
				text: I18n.t("errors.self_recommendation")
			@triggerRoute "/u/#{@model.get('id')}"

	# routing stuff
	navigateEducation: ->
		@triggerRoute "/u/#{@model.get('id')}/education"
	navigateWork: ->
		@triggerRoute "/u/#{@model.get('id')}/work"
	navigateCommonConnections: ->
		@triggerRoute "/u/#{@model.get('id')}/commonconnections"
	navigateCommonInterests: ->
		@triggerRoute "/u/#{@model.get('id')}/commoninterests"
	navigateReviews: ->
		@triggerRoute "/u/#{@model.get('id')}/reviews"
	navigateSignUp: ->
		@triggerRoute "/u/#{@model.get('id')}/signup"
	navigateEdit: ->
		@triggerRoute "/u/#{@model.get('id')}/edit"
	navigateRecommendationRequest: ->
		@triggerRoute "/u/#{@model.get('id')}/requestRecommendations"
	triggerRoute: (route, trigger = true) ->
		@router.navigate route, trigger: trigger, replace: true
