# = require jquery.foundation.tabs

class @ProfileNameView extends Backbone.View
  model: User
  className: 'name'
  template: _.template("<h1><%= model.get('name') %></h1>")
  initialize: (options) ->
    @model.on 'change', @render, this
  render: ->
    @$el.html @template model: @model
    this

class @ProfileTaglineView extends Backbone.View
  model: User
  className: 'tagline'
  template: _.template("<p><%= model.get('tagline') %></p>")
  initialize: (options) ->
    @model.on 'change', @render, this
  render: ->
    @$el.html @template model: @model
    this

class @ProfilePicView extends Backbone.View
  model: User
  events:
    'mouseenter': 'stopCycle'
    'mouseleave': 'startDelayedCycle'
    'click #profilepic_leftcycle': 'cycleLeft'
    'click #profilepic_rightcycle': 'cycleRight'
    'click li': 'pageindicator_click'
  initialize: (options) ->
    @parent = options.parent
    @on 'edit_on', @turnOnEdit, this
    @on 'edit_off', @turnOffEdit, this
    @model.on 'change', @render, this
  template: _.template "
  <div id='profilepic_viewhole'><div id='profilepic_canvas'></div></div>
  "
  cycleTemplate: _.template "
  <ul class='pageindicator'></ul>
  <a href='#' id='profilepic_leftcycle'></a>
  <a href='#' id='profilepic_rightcycle'></a>
  "
  
  stopCycle: ->
    clearTimeout @timeout
  startDelayedCycle: ->
    @timeout = setTimeout (=>
      @startCycle()
      ), 5000
  pageindicator_click: (evt) ->
    @cycleindex = $(evt.target).parent().index()
    @cycle()
  cycleLeft: ->
    @cycleindex = (@cycleindex - 1) % (@model.get('profile_pictures').length)
    if @cycleindex < 0
      @cycleindex = @model.get('profile_pictures').length - 1
    @cycle()
    return false;
  cycleRight: ->
    @cycleindex = (@cycleindex + 1) % (@model.get('profile_pictures').length)
    @cycle()
    return false;
  cycle: ->
    @canvas.css 'left', @cycleindex * -150
    @pageindicator.find('a li').removeClass 'selected'
    @pageindicator.children('a').eq(@cycleindex).children('li').addClass 'selected'
  startCycle: ->
    if @model.get('profile_pictures').length > 1
      @cycleRight()
      @timeout = setTimeout (=>
        @startCycle()
        ), 5000
  render: ->
    @$el.html @template()
    if @model.get('profile_pictures').length > 1
      @$el.append @cycleTemplate()
    @canvas = @$ '#profilepic_canvas'
    @canvas.css('width', @model.get('profile_pictures').length * 150)
    @pageindicator = @$ 'ul.pageindicator'
    @cycleindex = 0
    _.each @model.get('profile_pictures'), (value, index) =>
      @canvas.append "<div style='background-image: url(#{value});'></div>"
      @pageindicator.append('<a href="#"><li></li></a>')
    clearTimeout @timeout
    @startCycle()
    this