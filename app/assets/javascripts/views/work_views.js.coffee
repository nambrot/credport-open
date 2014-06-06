class @WorkAttributeDetailView extends Backbone.View
	initialize: ->
		@model.on 'change', =>
			@render()
	editMode: false
	enableEditing: ->
		@editMode = true
		@$el.on 'click', '.edittoggle', {}, =>
			@toggleVisibility()
		@renderEdit()
	disableEditing: ->
		@editMode = false
		@$('.edittoggle').remove()
	renderEdit: ->
		if @$('.edittoggle').length == 0
			$("<a class='button edittoggle'>#{I18n.t('Toggle Visibility')}</a>").insertBefore @$('h5')[0]
	toggleVisibility: ->
		console.log @model
		@model.toggleVisibility()
	className: 'work-attribute-detail-view'
	model: WorkAttribute
	template: _.template("
		<article class='timeline-entry'>
			<div class='timeline-entry-canvas row'>
				<section>
					<h5><%= title%></h5>
					<div class='object-box four columns'>
						<img src='<%= workplace.image %>' alt='' />
						<div class='content-box'>
							<a href='<%= workplace.url %>' target='_blank'><div class='title'><%= workplace.name %></div></a>
							<div class='subtitle'></div>
						</div>
					 <div class='row verified-by'>	
						<h5>#{I18n.t('Verified by')}</h5>
						<img src='<%= added_by.image %>' alt='' />
						<div class='content-box'>
							<a href='<%= added_by.url %>' target='_blank'><div class='title'><%= added_by.name %></div></a>
							<div class='subtitle'><%= added_by.context.title %></div>
						</div>
					 </div>
					</div>
					<div class='timeline-entry-canvas-attributes seven offset-by-one columns'>
						<% if ( date_string.length > 0 ) {%>	
						<div class='kvs'>
								<div class='key'>#{I18n.t('Time')}</div>
								<div class='value'><%= date_string %></div>
						</div>
						<% }  %>
						<% if (summary) { %>
							<div class='kvs'>
								<div class='key'>#{I18n.t('Summary')}</div>
								<div class='value'><%= summary %></div>
							</div>
						<% }  %>
						<!--% if (title) { %>
							<div class='kvs'>
								<div class='key'>#{I18n.t('Title')}</div>
								<div class='value'><%= title %></div>
							</div>
						<% }  % -->
					</div>
				</section>
				
				<!--section class='verified-by'>
					<h5>#{I18n.t('Verified by')}</h5>
					<div class='object-box'>
						<img src='<%= added_by.image %>' alt='' />
						<div class='content-box'>
							<a href='<%= added_by.url %>' target='_blank'><div class='title'><%= added_by.name %></div></a>
							<div class='subtitle'><%= added_by.context.title %></div>
						</div>
					</div>
				</section-->
			</div>
			
		</article>
	")
	render: ->
		@$el.html(@template(@model.toJSON()))
		@renderEdit() if @editMode
		this

class @WorkDetailView extends Backbone.View
	editMode: false
	enableEditing: ->
		@editMode = true
		@trigger 'edit_on'
	disableEditing: ->
		@editMode = false
		@trigger 'edit_off'
	className: 'work-detail-view'
	model: WorkHistory
	template: _.template("
	")
	header: "<h2>work</h2>"
	render: ->
		@$el.html(@template(@model.toJSON()))
		for index, model of @model.models
			ev = new WorkAttributeDetailView({model: model})
			@on 'edit_on', _.bind(ev.enableEditing, ev)
			@on 'edit_off', _.bind(ev.disableEditing, ev)
			ev.render()
			ev.enableEditing() if @editMode
			@$el.append ev.el
		this
