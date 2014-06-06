class @MetroBoxView extends Backbone.View
	enableEditing: ->
		@$('footer').text I18n.t('click to edit')
	disableEditing: ->
		@$('footer').text I18n.t('click to see more')
	events: 
		'click': 'trigger_click'
	trigger_click: (evt) ->
		@trigger('open')
	currentCyclingIndex: 0
	className: 'metro-box long hoverable'
	template: _.template("
		<h3><%= title %></h4>
		<div class='canvas'></div>
		<footer>#{I18n.t('click to see more')}</footer>
		<aside class='info'>
		  <span class='trigger'>?</span>
			<p><%= info %></p>
		</aside>
	")
	initialize: ->
		@on 'edit_on', @enableEditing, this
		@on 'edit_off', @disableEditing, this
	render: ->
		@$el.html(@template(title: @title, info: @info))
		div = @$('div.canvas')
		div.append this.boxcontext(@model.at(0).toJSON())
		this
	cyclingTimeout: ->
		Math.random() * 2000 + 5000
	startCycle: ->
		setTimeout(_.bind(@cycle, this), @cyclingTimeout())
	cycle: ->
		@currentCyclingIndex = (@currentCyclingIndex + 1) % @model.length
		@$('div.canvas').children().addClass('animated fadeOut')
		setTimeout (=>
			@$('div.canvas').children().remove()
			@$('div.canvas').append this.boxcontext(@model.at(@currentCyclingIndex).toJSON())
			@$('div.canvas').children().addClass('animated fadeIn')
			), 1000

		setTimeout(_.bind(@cycle, this), @cyclingTimeout())

class @EducationBoxView extends MetroBoxView
	id: 'educationbox'
	cyclingTimeout: ->
		Math.random() * 2000 + 10000
	title: I18n.t('education')
	info: I18n.t("Education_history")
	boxcontext: _.template("
		<div><%= classyear_string %></div>
			<br />
		 <div class='object-box'>
	 		<img src='<%= school.image %>' alt='' />
	 		<div class='content-box'>
	 			<div class='title'><%= key %></div>
	 			<div class='subtitle'><%= value %></div>
	 		</div> 
		</div>
	")

class @ReviewsBoxView extends MetroBoxView
	id: 'reviewbox'
	cyclingTimeout: ->
		Math.random() * 2000 + 5000
	info: I18n.t("Reviews from across networks")
	title: I18n.t('reviews')
	boxcontext: _.template("
		<p>
			<%= connections[0].properties.text %>
		</p>
	")
	render: ->
		@$el.html(@template(title: @title, info: @info))
		div = @$('div.canvas')
		div.append this.boxcontext(@model.at(0).toJSON())
		$clamp @$('div.canvas p')[0], clamp: 4
		this
	cycle: ->
		@currentCyclingIndex = (@currentCyclingIndex + 1) % @model.length
		@$('div.canvas').children().addClass('animated fadeOut')
		setTimeout (=>
			@$('div.canvas').children().remove()
			@$('div.canvas').append this.boxcontext(@model.at(@currentCyclingIndex).toJSON())
			@$('div.canvas').children().addClass('animated fadeIn')
			$clamp @$('div.canvas p')[0], clamp: 4
			), 1000

class @WorkBoxView extends MetroBoxView
	id: 'workbox'
	cyclingTimeout: ->
		Math.random() * 2000 + 10000
	title: I18n.t('work')
	info: I18n.t('Work_history')
	boxcontext: _.template("
		<div><%= date_string %></div>
		<br />
		 <div class='object-box'>
	 		<img src='<%= workplace.image %>' alt='' />
	 		<div class='content-box'>
	 			<div class='title'><%= workplace.name %></div>
	 			<div class='subtitle'><%= title %></div>
	 		</div> 
		</div>
	")

class @CommonConnectionsBoxView extends MetroBoxView
	id: 'ccbox'
	title: I18n.t('common connections')
	info: I18n.t("See how you are connected")
	boxcontext: _.template("
		 <div class='object-box'>
				<img src='<%= nodes[1].image %>' alt='' />
				<div class='content-box'>
					<div class='title'><%= nodes[1].name %></div>
					<div class='subtitle'><%= nodes[1].context.title %></div>
				</div> 
		</div>
	")

class @CommonInterestsBoxView extends MetroBoxView
	id: 'cibox'
	title: I18n.t('common interests')
	info: I18n.t("Things you both like")
	boxcontext: _.template("
		 <div class='object-box'>
				<img src='<%= nodes[1].image %>' alt='' />
				<div class='content-box'>
					<div class='title'><%= nodes[1].name %></div>
					<div class='subtitle'><%= nodes[1].context.title %></div>
				</div> 
		</div>
	")

class @SignUpBoxView extends Backbone.View
	model: User
	template: _.template("
		<h3>#{I18n.t('common connections')}</h3>
		<div class='canvas'>
			<div class='object-box'>
	 			<img src='https://credport-assets.s3.amazonaws.com/assets/user-165667edcf8102e2cdc16d9c42f22551.png' alt='' />
	 			<div class='content-box'>
	 				<div class='title'>#{I18n.t('box_views.signupbox.person.title')}</div>
	 				<div class='subtitle'>#{I18n.t('box_views.signupbox.person.subtitle')}</div>
	 			</div> 
	 		</div>
	 		<div style='margin-top:15px;'>
	 			<p><%= I18n.t('box_views.signupbox.prompt', {name: name.split(' ')[0]} ) %></p>
	 		</div>
	 		
		
		</div>
		<footer>#{I18n.t('box_views.signupbox.clickmore')}</footer>
		<aside class='info'>
		  <span class='trigger'>?</span>
			<p><%= I18n.t('box_views.signupbox.info', {name: name.split(' ')[0]} ) %></p>
		</aside>
	")
	events: 
		'click': 'trigger_click'
	trigger_click: (evt) ->
		@trigger('open')
	className: 'metro-box long hoverable signup-box'
	initialize: ->
		mixpanel.track("Profile:SignUpBox:Init")
	render: ->
		@$el.html(@template(@model.toJSON()))
		this

class @RecommendationsBoxView extends Backbone.View
	model: User
	template: _.template("
		<h3>#{I18n.t('box_views.recommendationsbox.title')}</h3>
		<div class='canvas'>
	 		<div style='margin-top:15px;'>
	 			<p><%= I18n.t('box_views.recommendationsbox.prompt', { count: model.length } ) %> <%= I18n.t('box_views.recommendationsbox.prompt2', {count: recommendations.length}) %></p>
	 		</div>
		</div>
		<footer>#{I18n.t('box_views.recommendationsbox.clickmore')}</footer>
		<aside class='info'>
		  <span class='trigger'>?</span>
			<p><%= I18n.t('box_views.recommendationsbox.info') %></p>
		</aside>
	")
	events: 
		'click': 'trigger_click'
	trigger_click: (evt) ->
		@trigger('open')
	className: 'metro-box long hoverable recommendations-box'
	startCycle: ->
	initialize: ->
		mixpanel.track("Profile:RecommendationsBox:Init")
		@model.reviews (reviews) =>
			@model.recommendations_to_approve (recommendations) =>
				@reviews = reviews
				@recommendations = recommendations
				@render()
	render: ->
		@$el.html(@template(model: @reviews, recommendations: @recommendations))
		@$el.addClass 'show'
		this