class @NewUserOverlay extends Backbone.View
  template: _.template("
      <div id='document-overlay-box'>
        <h3>#{I18n.t('Build_credport')}</h3>
        <p>
          #{I18n.t('Build_message')}
        </p>
        <a href='#' class='button remove'>Close</a>
      <span class='delete'></span>
      </div>
  ")
  close: (e) ->
    return false;
  remove: ->
    @overlay.addClass 'animated bounceOutDown'
    @box.addClass 'animated bounceOutUp'
    setTimeout (=>
      @overlay.remove()
      @box.remove()
      ), 1000
    return false;
  render: ->
    @overlay = $('<div id="document-overlay"></div>')
    $('body').append @overlay
    @overlay.addClass 'animated fadeIn'
    @overlay.on 'click', null, null, _.bind @remove, this
    @box = $ @template()
    $('body').append @box
    @box.on 'click', '.delete', null, _.bind @remove, this
    @box.on 'click', '.remove', null, _.bind @remove, this
    @box.click (e) ->
      if !$(this).find('a').is e.target
        return false
    @box.addClass 'animated fadeInUp'
    this