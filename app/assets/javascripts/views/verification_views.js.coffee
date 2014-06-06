class @VerificationView extends Backbone.View
	tagName: 'li'
	className: 'verification object-box'
	events:
		'click a': 'clickVerification'
	clickVerification: (evt) ->
		mixpanel.track "Profile:Website:Click", url: evt.target.href
		mixpanel.people.increment "Profile:Website:Click"
	template: _.template("
		<img src='<%= image %>' alt='' />
		<div class='content-box'>
			<% if (properties.url == null){ %>
			<div class='title'><%= title %></div>
			<% } else { %>
			<a href='<%= properties.url %>' target='_blank' class='title'><%= title %></a>
			<% } %>
			<div class='subtitle'><%= subtitle %></div>
		</div>
	")
	render: ->
		@$el.html(@template(@model.toJSON()))
		this

class @VerificationCollectionView extends Backbone.View
	id: 'verifications'
	className: 'verifications'
	template: _.template("
		<h4>#{I18n.t('verifications')}</h4>
		<div class='verifications_adder'>
			<a href='verify' class='button'>#{I18n.t('Add more Verifications')}</a></div>
		<ul></ul>
		<aside class='info'>
		  <span class='trigger'>?</span>
			<p>#{I18n.t('verification.explanation')}</p>
		</aside>
	")
	initialize: ->
		@model.on 'add remove', @render, this
		@on 'edit_on', =>
			@turnOnEdit()
		@on 'edit_off', =>
			@turnOffEdit()
	render: ->
		@$el.html(@template())
		@editingpane = @$('.verifications_adder')
		@editingpane.find('a').click (evt) =>
			@trigger 'route', "/u/#{@model.user.get('id')}/verify" , true
			return false
		ul = @$('ul')
		for index, verification of @model.models
			view = new VerificationView({model: verification})
			view.render()
			ul.append(view.el)
		this
	turnOnEdit: ->
		@editingpane.addClass 'show'
	turnOffEdit: ->
		@editingpane.removeClass 'show'

class @EmailView extends Backbone.View
	model: Email
	tagName: 'li'
	events: {
		'click a.resend': 'resend'
	}
	template: _.template("
<span class='email'><%= email %></span> <a href='#' class='resend'>#{I18n.t('Resend Code')}</a>
	")
	resend: ->
		$.post("/resend/email", email: @model.get('email'), null, 'json')
			.success (resp) =>
				$.gritter.add
					title: I18n.t('Success')
					# TODO: I18n
					text: resp.success
			.error (xhr, state, error) ->
				$.gritter.add 
					title: I18n.t('Error')
					text: I18n.t("Something went wrong")
		return false
	render: ->
		@$el.html(@template(email: @model.get('email')))
		this

class @PhoneView extends Backbone.View
	model: Phone
	tagName: 'li'
	events: {
		'click a.resend': 'resend'
	}
	template: _.template("
<span class='phone'><%= phone %></span> <a href='#' class='resend'>#{I18n.t('Resend Code')}</a>
	")
	resend: ->
		$.post("/resend/phone", phone: @model.get('phone'), null, 'json')
			.success (resp) =>
				$.gritter.add
					title: I18n.t('Success')
					# TODO: I18n
					text: resp.success
			.error (xhr, state, error) ->
				$.gritter.add 
					title: I18n.t('Error')
					text: I18n.t("Something went wrong")
		return false
	render: ->
		@$el.html(@template(phone: @model.get('phone_formatted')))
		return this

class @WebsiteView extends Backbone.View
	model: Website
	tagName: 'li'
	events: {
		'click a.check': 'check'
	}
	template: "
<a target='_blank' href='<%= url %>' class='url'><b><%= title %></b></a> <%= I18n.t('webpage.with_code', {verification_code: verification_code}) %> <br> <a href='#website' class='check button'> <b><%= I18n.t('Check website', { title: title, verification_code: verification_code }) %></b> </a>
	"
	check: ->
		$.post("/u/#{@model.collection.user.get('id')}/websites/#{@model.get('id')}/check", {}, null, 'json')
			.success (resp) =>
				@model.collection.user.verifications (verifications) ->
					verifications.add resp.verification
				@model.collection.remove @model
				$.gritter.add
					title: I18n.t('Success')
					# TODO: I18n
					text: resp.success
			.error (xhr, state, error) ->
				$.gritter.add 
					title: I18n.t('Error')
					text: JSON.parse(xhr.responseText).errors
		return false
	render: ->
		@$el.html(_.template(@template)(@model.toJSON()))
		this