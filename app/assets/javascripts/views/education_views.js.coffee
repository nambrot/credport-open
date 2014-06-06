class @EducationAttributeDetailView extends Backbone.View
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
		@model.toggleVisibility()
	className: 'education-attribute-detail-view'
	model: EducationAttribute
	template: _.template("
		<article class='timeline-entry'>
			<div class='timeline-entry-canvas row'>
				<section>
					<h5>#{I18n.t('School')}</h5>
					<div class='object-box four columns'>
						<img src='<%= school.image %>' alt='' />
						<div class='content-box'>
							<a href='<%= school.url %>' target='_blank'><div class='title'><%= school.name %></div></a>
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
						<div class='kvs'>
								<div class='key'>#{I18n.t('Station')}</div>
								<div class='value'><%= station %></div>
							</div>
						<% if (majors.length > 0) { %>
							<div class='kvs'>
								<div class='key'>#{I18n.t('Major')}</div>
								<div class='value'><%= majors.join(', ') %></div>
							</div>
						<% }  %>
					</div>
				</section>
			</div>
			
		</article>
	")
	render: ->
		@$el.html(@template(@model.toJSON()))
		@renderEdit() if @editMode
		this

class @EducationDetailView extends Backbone.View
	editMode: false
	enableEditing: ->
		@editMode = true
		@trigger 'edit_on'
	disableEditing: ->
		@editMode = false
		@trigger 'edit_off'
	className: 'education-detail-view'
	model: EducationHistory
	template: _.template("
	")
	header: "<h2>education</h2>"
	render: ->
		@$el.html(@template(@model.toJSON()))
		for index, model of @model.models
			ev = new EducationAttributeDetailView({model: model})
			@on 'edit_on', _.bind(ev.enableEditing, ev)
			@on 'edit_off', _.bind(ev.disableEditing, ev)
			ev.render()
			ev.enableEditing() if @editMode
			@$el.append ev.el
		this
