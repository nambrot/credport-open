# = require jquerymod
# = require clamp
# = require backbone-rails
# = require i18n
# = require i18n/translations
I18n.defaultLocale = "en";
I18n.fallbacks = true;
if window.credport? and window.credport.locale?
  I18n.locale = window.credport.locale

jQuery.noConflict()
class @User extends Backbone.Model
  urlRoot: '/api/v1/users'
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
    callback @reviewsobject
  commonconnections: (callback) ->
    if !@commonconnectionsobject?
      @commonconnectionsobject = new CommonConnections()
      @commonconnectionsobject.user = this
      @commonconnectionsobject.url = @get('links').commonconnections
      @commonconnectionsobject.on 'reset', (evt) =>
        callback @commonconnectionsobject
      @commonconnectionsobject.fetch()
    else
      callback @commonconnectionsobject
  commoninterests: (callback) ->
    if !@commoninterestsobject?
      @commoninterestsobject = new CommonInterests()
      @commoninterestsobject.user = this
      @commoninterestsobject.url = @get('links').commoninterests
      @commoninterestsobject.on 'reset', (evt) =>
        callback @commoninterestsobject
      @commoninterestsobject.fetch()
    else
      callback @commoninterestsobject
  stats: (callback) ->
    if !@statsobject?
      @statsobject = new Stats()
      @statsobject.user = this
      @statsobject.url = @url() + '/stats/'
      @statsobject.on 'change', (evt) =>
        callback @statsobject
      @statsobject.fetch()
    else
      callback @statsobject
  getstats: ->
    stats = @get('stats')

class Identity extends Backbone.Model

class Review extends Backbone.Model
class Reviews extends Backbone.Collection
  model: Review
class Path extends Backbone.Model
  nodes: ->
    if !@nodesobject?
      @nodesobject = _.map @get('nodes'), (node) ->
        new Identity(node)
    @nodesobject
  connections: ->
    @get('connections')
      
class CommonConnections extends Backbone.Collection
  model: Path
  sync: (method, model, options) ->
      params = _.extend({
        type:         'GET',
        dataType:     'jsonp',
        url:      model.url,
        jsonp:    "callback",   
        processData:  false
      }, options)
      jQuery.ajax(params)
  parse: (resp, xhr) -> 
    resp.data
    
class CommonInterests extends Backbone.Collection
  model: Path
  sync: (method, model, options) ->
      params = _.extend({
        type:         'GET',
        dataType:     'jsonp',
        url:      model.url,
        jsonp:    "callback",   
        processData:  false
      }, options)
      jQuery.ajax(params)
  parse: (resp, xhr) -> 
    resp.data
class Overlay extends Backbone.View
  id: 'credport-overlay'
  events: 
    'click .close': 'close'
    'click': 'stopPropagation'
  stopPropagation: (evt) ->
    evt.stopPropagation()
  close: ->
    @$el.removeClass 'display'
    setTimeout (=>
      @$el.remove()
      ), 500
    return false
  render: ->
    url = @model.get('url')
    url += '?source=badgeoverlayiframe'
    url += "&tlocale=" + window.credport.locale if (window.credport? and window.credport.locale?)
    @$el.html "<header><p>#{I18n.t('badge.overlay.title', url: @model.get('url'))}</p></header><span class='close'></span><div id='credport-overlay-iframe-container'><svg class='shadow' pointer-events='none'></svg><iframe src='#{url}'></iframe></div>"
    @document = jQuery(document)
    jQuery('body').append @$el
    jQuery(document).on 'keydown.overlay', null, {}, (evt) =>
      if evt.which == 27
        @close()
        jQuery(document).off 'keydown.overlay'
    setTimeout (=>
      @$el.addClass 'display'
      jQuery(document).on 'click.overlay', null, {}, (evt) =>
        jQuery(document).off 'click.overlay'
        @close()
      ), 40
    this
class UserButtonView extends Backbone.View
  model: User
  show_identities_on_badge: false
  initialize: (options) ->
    @model.on 'change', @render, this
    @show_identities_on_badge = options.show_identities_on_badge if options.show_identities_on_badge?
  events:
    "click #credport-button-openProfile": "openProfile"
    "mouseenter .credport-button-stats-number": 'show_stats_number'
    "mouseleave .credport-button-stats-number": 'hide_stats_number'
  show_stats_number: (evt) ->
    @$('#credport-button-user-header').css 'visibility', 'hidden'
    @$('#credport-button-cover-photo').addClass 'hide-credport-button-cover-photo'
    @$('#credport-button-cover-photo-gradient').html(jQuery(evt.currentTarget).find('.credport-button-stats-popup').clone())
  hide_stats_number: (evt) ->
    @$('#credport-button-user-header').css 'visibility', 'visible'
    @$('#credport-button-cover-photo').removeClass 'hide-credport-button-cover-photo'
    @$('#credport-button-cover-photo-gradient').html('')
  openProfile: ->
    overlay = new Overlay(model: @model).render()
    return false
    # TODO: watch out XSS
    # first div to make the top look ok
  template: "
    <div></div>
    <div id='credport-button-cover-photo' style='background-image: url(<%= user.background_picture %>)'>
      <div id='credport-button-cover-photo-gradient'></div>
    </div>
    <div id='credport-button-user-header'>
      <img src='<%= user.image %>' alt=''>
      <div id='credport-button-user-header-name'><%= user.name %></div>
      <div id='credport-button-user-header-tagline'><%= user.tagline %></div>
    </div>
    <div id='credport-button-stats'>
      
    </div>
    <p class='credport-button-padded credport-button-openProfile'><a id='credport-button-openProfile' href='<%= user.url %>' target='_blank'>#{I18n.t('badge.openProfile')}</a></p>
  "
  statTemplate: _.template "
    <div id='credport-button-stats-<%= key %>' class='credport-button-stats-number'>
      <img src='<%= value.image %>' alt=''>
      <span class='credport-button-stats-number-number'><%= value.number %></span>
      <div class='credport-button-stats-popup' id='credport-button-stats-popup-<%= key %>'><div id='credport-button-stats-popup-header'><%= value.desc %></div><p></p></div>
    </div>
  "
  render: ->
    @$el.html _.template(@template) user: @model.toJSON()
    if @show_identities_on_badge
      @$('#credport-button-user-header').append("<ul id='credport-button-user-header-identities'></ul>")
      for identity in @model.get('verifications').identities
        @$('#credport-button-user-header-identities').append "<li><a href='#{identity.url}'><img src='#{identity.image}' alt=''></a></li>"
    count = 0
    for k,v of @model.get('stats')
      if v.number != 0 and count < 3
        @$('#credport-button-stats').append @statTemplate(key:k, value:v)
        count++
    @renderStatsOverlays()
    this
  renderStatsOverlays: ->
    for k,v of @model.get('stats')
      switch k
        when 'degree_of_seperation'
          if @$('#credport-button-stats-degree_of_seperation').length > 0
            @$('#credport-button-stats-popup-degree_of_seperation').html( I18n.t('badge.stats.overlay.dos', {count: @model.get('stats').degree_of_seperation.number, name: @model.get('name') }))
        when 'reviews'
          if @$('#credport-button-stats-reviews').length > 0
            @model.reviews (reviews) =>
              @$('#credport-button-stats-popup-reviews').html("<div id='credport-button-stats-popup-header'>#{I18n.t('badge.stats.overlay.reviews.title', {count: @model.get('stats').reviews.number})}</div><p id='credport-button-stats-reviews-header'><img src='#{reviews.models[0].attributes.nodes[0].image}' alt=''><span>#{reviews.models[0].attributes.nodes[0].name}</span> #{I18n.t('reviewed')} <img src='#{reviews.models[0].attributes.nodes[1].image}' alt=''><span>#{reviews.models[0].attributes.nodes[1].name}</span>:</p><p id='credport-button-stats-reviews-body'>#{reviews.models[0].attributes.connections[0].properties.text}</p><p id='credport-button-stats-popup-footer'>#{I18n.t('badge.stats.overlay.reviews.footer', {count: @model.get('stats').reviews.number - 1})}</p>")
              $clamp @$('#credport-button-stats-reviews .credport-button-stats-popup #credport-button-stats-reviews-body')[0], clamp: 3
        when 'common_connections'
          if @$('#credport-button-stats-common_connections').length > 0
            @model.commonconnections (commonconnections) =>
              @$('#credport-button-stats-popup-common_connections').html("<div id='credport-button-stats-popup-header'>#{I18n.t('badge.stats.overlay.cc.title', count: @model.get('stats').common_connections.number, name: @model.get('name'))}</div><p id='credport-button-stats-popup-common_connections-connections'></p>")
              preview = commonconnections.models.slice(0,10)
              for index,connection of preview
                @$('#credport-button-stats-popup-common_connections-connections').append("<img src='#{connection.attributes.nodes[1].image}' alt=''>")
              if @model.get('stats').common_connections.number > 10
                @$('#credport-button-stats-popup-common_connections-connections').append I18n.t('badge.stats.overlay.cc.footer', count: @model.get('stats').common_connections.number - 10)
        when 'accounts'
          if @$('#credport-button-stats-accounts').length > 0
            @$('#credport-button-stats-popup-accounts').html("<div id='credport-button-stats-popup-header'>#{I18n.t('badge.stats.overlay.accounts.title', count: @model.get('stats').accounts.number)}</div><p>#{I18n.t('badge.stats.overlay.accounts.description', count: @model.get('stats').accounts.number, name: @model.get('name'))}</p><ul id='credport-button-stats-popup-accounts-images'></ul>")
            for account in @model.get('verifications').identities.slice(0,10)
              @$('#credport-button-stats-popup-accounts-images').append("<li><a href='#{account.url}'><img src='#{account.image}' alt=''></a></li>")
        when 'verifications'
          if @$('#credport-button-stats-verifications').length > 0
            @$('#credport-button-stats-popup-verifications').html("<div id='credport-button-stats-popup-header'>#{I18n.t('badge.stats.overlay.verifications.title', count: @model.get('stats').verifications.number)}</div><p>#{I18n.t('badge.stats.overlay.verifications.description', count: @model.get('stats').verifications.number, name: @model.get('name'))}</p>")
        when 'common_interests'
          if @$('#credport-button-stats-common_interests').length > 0
            @model.commoninterests (common_interests) =>
              @$('#credport-button-stats-popup-common_interests').html("<div id='credport-button-stats-popup-header'>#{I18n.t('badge.stats.overlay.ci.title', count: @model.get('stats').common_interests.number, name: @model.get('name'))}</div><p id='credport-button-stats-popup-common_interests-connections'></p>")
              preview = common_interests.models.slice(0,10)
              for index,connection of preview
                @$('#credport-button-stats-popup-common_interests-connections').append("<img src='#{connection.attributes.nodes[1].image}' alt=''>")
              if @model.get('stats').common_interests.number > 10
                @$('#credport-button-stats-popup-common_interests-connections').append I18n.t('badge.stats.overlay.ci.footer', count: @model.get('stats').common_interests.number - 10)


              
window.renderCredportButton = (idhash, baseUrl = 'http://www.credport.org' , selector = "#credport-button") ->
  id = idhash.id || 1
  delete idhash['id']
  # add locale if necessary
  if window.credport? and window.credport.locale?
    idhash['tlocale'] = window.credport.locale
  # custom for usetwice, show identities if want to
  show_identities_on_badge = if window.credport? and window.credport.show_identities_on_badge? then true else false
  querystring = ("#{key}=#{value}" for key, value of idhash).join('&')
  jQuery.ajax
      type: 'GET'
      url: "#{baseUrl}/api/v1/users/#{id}?#{querystring}&include=verifications,stats,reviews"
      async: false
      contentType: "application/json"
      dataType: 'jsonp'
      success: (resp) ->
        if resp.status == 200
          user = new User resp.user
          userview = new UserButtonView({model: user, el: jQuery(selector)[0], show_identities_on_badge: show_identities_on_badge})
          userview.render()

jQuery ->
  baseUrl = if window.credport? and window.credport.baseUrl? then window.credport.baseUrl else 'https://www.credport.org';
  if window.credport? and window.credport.user?
    renderCredportButton window.credport.user, baseUrl
  window.credport_sign_popup = ->
    width= screen.width * 0.8
    width = 1200 if width > 1200
    height = screen.height * 0.8
    left = (screen.width - width) / 2
    top = (screen.height - height) / 2
    url = "#{baseUrl}/signup?source=badge"
    url += "?tlocale=" + window.credport.locale if (window.credport? and window.credport.locale?)
    newwindow=window.open(url,'Credport - Sign Up',"height=#{height},width=#{width},top=#{top},left=#{left}")
    class Check
      check: ->
        if newwindow.closed
          window.renderButton idhash
        else
          setTimeout (=>
            @check()), 500
    new Check().check()
    return false
  jQuery("#credport-signup").click window.credport_sign_popup
