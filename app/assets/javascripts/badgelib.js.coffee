# = require jquerymod
# = require backbone-rails
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
      @commonconnectionsobject.url = @url() + '/commonconnections/'
      @commonconnectionsobject.on 'reset', (evt) =>
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
class Identity extends Backbone.Model

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
  parse: (resp, xhr) -> 
    resp.data
    
class CommonInterests extends Backbone.Collection
  model: Path
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
    @$el.html "<header><p>Check out this Credport profile in full size: <a href='#{@model.get('url')}'>#{@model.get('url')}</a></p></header><span class='close'></span><div id='credport-overlay-iframe-container'><svg class='shadow' pointer-events='none'></svg><iframe src='#{@model.get('url')}'></iframe></div>"
    @document = jQuery(document)
    jQuery('body').append @$el
    jQuery(document).on 'keydown.overlay', null, {}, (evt) =>
      @close() if evt.which == 27
    setTimeout (=>
      @$el.addClass 'display'
      jQuery(document).on 'click.overlay', null, {}, (evt) =>
        @close()
      ), 40
    this
class UserButtonView extends Backbone.View
  model: User
  initialize: ->
    @model.on 'change', @render, this
  events:
    "click #openProfile": "openProfile"
  openProfile: ->
    overlay = new Overlay(model: @model).render()
    return false
    # TODO: watch out XSS
  template: _.template "
<header>
  <img src='<%= user.image %>' />
  <h3><%= user.name %></h3>
</header>
<% if (user.verifications.identities.length > 0) {%>
  <section id='verifications'>   
    
    <div class='identities'>
<% for (var i = 0; i < user.verifications.identities.length && i < 3; i++){ %>
      <img class='credport-profile-identity' src='<%= user.verifications.identities[i].image %>'>   
    <% } %>
      </div>
   <div class='body'>

    </div>
    </section>
<% } %>
<% if (commonconnections && commonconnections.models.length > 0) {%>
  <section id='verifications'>   
    <header>
      <h4>Common Connections</h4>
    </header>
   <% for (var i = 0; i < commonconnections.models.length && i < 3; i++){ %>
      <img class='credport-profile-identity' src='<%= commonconnections.models[i].get('nodes')[1].image %>'>   
    <% } %>
    <% if (user.stats.common_connections.number > 3) {%>
      and <%= user.stats.common_connections.number - 3 %> more
    <% } %>
    </section>
<% } %>
<% if (commoninterests && commoninterests.models.length > 0) {%>
  <section id='verifications'>   
    <header>
      <h4>Common Interests</h4>
    </header>
   <% for (var i = 0; i < commoninterests.models.length && i < 3; i++){ %>
      <img class='credport-profile-identity' src='<%= commoninterests.models[i].get('nodes')[1].image %>'>   
    <% } %>
    <% if (user.stats.common_interests.number > 3) {%>
      and <%= user.stats.common_interests.number - 3 %> more
    <% } %>
    
    
    </section>
<% } %>
<p><a id='openProfile' href='<%= user.url %>' target='_blank'>Open Profile (in Popup)</a></p>
<aside id='credport-button-helper'>
  <span id='credport-button-helper-trigger'>?</span>
  <p>This is a profile created on Credport, your place to let others get to know you. Sign up to see how you are connected.</p>
</aside>
<footer><a href='https://www.credport.org'>Trust delivered by Credport</a></footer>
  "
  statTemplate: _.template "
    <div class='number'>
      <h3><%= number %></h3>
      <h6><%= title %></h6>
    </div>
  "
  render: ->
    @$el.html @template user: @model.toJSON(), commonconnections: @model.commonconnectionsobject, commoninterests: @model.commoninterestsobject
    count = 0
    for k,v of @model.get('stats')
      if v.number != 0 and count < 3 and k!='common_connections' and k!= 'common_interests'
        @$('#verifications .body').append @statTemplate v
        count++
    this
    this

window.renderCredportButton = (idhash, baseUrl = 'https://www.credport.org' , selector = "#credport-button") ->
  id = idhash.id || 1
  delete idhash['id']
  querystring = ("#{key}=#{value}" for key, value of idhash).join('&')
  jQuery.ajax
      type: 'GET'
      url: "#{baseUrl}/api/v1/users/#{id}?#{querystring}&include=verifications,stats"
      async: false
      contentType: "application/json"
      dataType: 'jsonp'
      success: (resp) ->
        if resp.status == 200
          user = new User resp.user
          userview = new UserButtonView({model: user, el: jQuery(selector)[0]})
          userview.render()
          countdown = 2
          cb = ->
            countdown = countdown - 1
            user.trigger 'change' if countdown == 0
          jQuery.ajax
              type: 'GET'
              url: "#{baseUrl}/api/v1/users/#{user.get('id')}/commonconnections"
              contentType: "application/json"
              dataType: 'jsonp'
              success: (resp) ->
                user.commonconnectionsobject = new CommonConnections resp.data              
              complete: cb
          jQuery.ajax
              type: 'GET'
              url: "#{baseUrl}/api/v1/users/#{user.get('id')}/commoninterests"
              contentType: "application/json"
              dataType: 'jsonp'
              success: (resp) ->
                user.commoninterestsobject = new CommonInterests resp.data
              complete: cb
jQuery ->
  baseUrl = if window.credport? and window.credport.baseUrl? then window.credport.baseUrl else 'https://www.credport.org'
  if window.credport? and window.credport.user?
    renderCredportButton window.credport.user, baseUrl
  jQuery("#credport-signup").click ->
    width= screen.width * 0.8
    width = 1200 if width > 1200
    height = screen.height * 0.8
    left = (screen.width - width) / 2
    top = (screen.height - height) / 2
    newwindow=window.open("#{baseUrl}/signup",'Credport - Sign Up',"height=#{height},width=#{width},top=#{top},left=#{left}")
    class Check
      check: ->
        if newwindow.closed
          window.renderButton idhash
        else
          setTimeout (=>
            @check()), 500
    new Check().check()
    return false
