class @ReviewDetailView extends Backbone.View
  model: Review
  tagName: 'article'
  className: 'review-detail-view'
  template: _.template("
      <header>
        <div class='inline-box'>
            <img src='<%= nodes[0].image %>' alt='' />
            <span><a href='<%= nodes[0].url %>'><%= nodes[0].name %></a></span>
          </div>

        <%= connections[0].context.properties.verbs.forward %>

        <div class='inline-box'>
            <img src='<%= nodes[1].image %>' alt='' />
            <span><a href='<%= nodes[1].url %>'><%= nodes[1].name %></a></span>
    
          </div>
      </header>
      <p>
        <%= connections[0].properties.text %>
      </p>
      <footer>
on 
        <div class='inline-box'>
            <img src='<%= connections[0].context.application.image %>' alt='' />
              <a href='<%= connections[0].context.application.url %>'><span><%= connections[0].context.application.name %></span></a>
          </div>
      </footer>
  ")
  render: ->
    console.log @model
    @$el.html @template @model.toJSON()
    this

class @ReviewsOverlayView extends Backbone.View
  className: 'reviews-detail-view'
  model: Reviews
  template: _.template("
  ")
  header: "<h2>#{I18n.t('reviews')}</h2>"
  render: ->
    @$el.html(@template(@model.toJSON()))
    for index, model of @model.models
      ev = new ReviewDetailView({model: model})
      ev.render()
      @$el.append ev.el
    this