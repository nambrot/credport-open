class @StatsView extends Backbone.View
  id: 'user-stats-view'
  statTemplate: _.template "
  <div class='metro-box number show'>
    <div class='canvas'>
      <header>
        <img src='<%= image %>' />
        <h3><%= number %></h3>
        <h6><%= title %></h6>
      </header>
      <p><%= desc %></p>
    </div>
  </div> 
  "
  render: ->
    @$el.html ''
    count = 0
    for k,v of @model.attributes
      if v.number != 0 and count < 4
        el = $(@statTemplate v)
        @$el.append el
        switch k
          when 'reviews'
            $(el).click =>
              @trigger 'route', "/u/#{@model.user.get('id')}/reviews", true
          when 'common_connections'
            $(el).click (e) =>
              @trigger 'route', "/u/#{@model.user.get('id')}/commonconnections", true
          when 'common_interests'
            $(el).click (e) =>
              @trigger 'route', "/u/#{@model.user.get('id')}/commoninterests", true
        count++
    this