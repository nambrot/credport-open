# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
# = require jquery
# = require jquery_ujs
# = require gritter
# = require backbone-rails
# = require models/user
# = require views/profile_view
# = require routers/profile_router
window.buildUserProfile = (attributes, self = false, current_user = null) ->
  user = new User attributes
  router = new ProfileRouter()
  view = new ProfileView 
    router: router
    model: user 
    el:$('#user-container')[0]
    current_user: current_user
    allowEdit: self
  view.render()
  Backbone.history.start({pushState: true})
  $('#user-loading-indicator').remove()
  