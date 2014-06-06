class @CommonConnectionDetailView extends Backbone.View
	className: 'common-connection-detail-view'
	model: Path
	tagName: 'li'
	template: _.template("
			<div>
				You <%= connections[0].context.properties.verbs.common_connection %>
			</div>
			<div class='object-box'>
					<img src='<%= nodes[1].image %>' alt='' />
					<div class='content-box'>
						<a href='<%= nodes[1].url %>'><div class='title'><%= nodes[1].name %></div></a>
						<div class='subtitle'><%= nodes[1].context.title %></div>
					</div>
				</div>
		
	")
	render: ->
		@$el.html(@template(@model.toJSON()))
		this

class @CommonConnectionsDetailView extends Backbone.View
	className: 'common-connections-detail-view'
	model: CommonConnections
	initialize: ->
		@model.on 'reset', @render, this
	template: _.template("
		<ul></ul>
	")
	header: "<h2>#{I18n.t('common connections')}</h2>"
	render: ->
		@$el.html(@template(@model.toJSON()))
		ul = @$ 'ul'
		for index, model of @model.models
			ev = new CommonConnectionDetailView({model: model})
			ev.render()
			ul.append ev.el
		this

class @CommonInterestDetailView extends Backbone.View
	className: 'common-interest-detail-view'
	model: Path
	tagName: 'li'
	initialize: ->
		@model.on 'reset', @render, this
	template: _.template("
		<div>
				You <%= connections[0].context.properties.verbs.common_interest %>
			</div>
		<div class='object-box'>
					<img src='<%= nodes[1].image %>' alt='' />
					<div class='content-box'>
						<a href='<%= nodes[1].url %>'><div class='title'><%= nodes[1].name %></div></a>
						<div class='subtitle'><%= nodes[1].context.title %></div>
					</div>
				</div>
	")
	render: ->
		@$el.html(@template(@model.toJSON()))
		this

class @CommonInterestsDetailView extends Backbone.View
	className: 'common-interests-detail-view'
	model: CommonInterests
	initialize: ->
		@model.on 'reset', @render, this
	template: _.template("
		<ul></ul>
	")
	header: "<h2>#{I18n.t('common interests')}</h2>"
	render: ->
		@$el.html(@template(@model.toJSON()))
		ul = @$ 'ul'
		for index, model of @model.models
			ev = new CommonInterestDetailView({model: model})
			ev.render()
			ul.append ev.el
		this