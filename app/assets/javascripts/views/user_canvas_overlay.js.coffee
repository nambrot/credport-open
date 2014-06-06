class @UserCanvasOverlay extends Backbone.View
  id: 'user-canvas-overlay'
  editMode: false
  events: 
    'click .close': 'close'
  template: _.template("
    <header id='user-canvas-overlay-header'></header><span class='close'></span><div id='user-canvas-overlay-canvas'></div>
  ")
  close: ->
    @trigger 'close'
    return false
  remove: ->
    $(document).off 'click.usercanvasoverlay'
    $(document).off 'keydown.usercanvasoverlay'
    @$el.removeClass 'fadeInRight'
    @$el.addClass 'fadeOutRight'
    setTimeout ( =>
      @$el.remove()
    ), 400
  addSubview: (view) ->
    @canvas.append view.el
    @header.html view.header
    view.trigger 'attached'
  render: ->
    @$el.html @template()
    @$el.addClass 'fadeInRight'
    @canvas = @$ '#user-canvas-overlay-canvas'
    @header = @$('#user-canvas-overlay-header')
    @document = $(document)
    cb = =>
      left = (@document.width() - 1280)/2 + 330
      if left < 330
        if left > 150
          @$el.css
            'left': 330
            'width': @document.width() - 360
        else
          @$el.css
            'left': '5%'
            'width': '90%'
      else
        @$el.css 'left', left
      # set height of the canvas
      @canvas.css('height', @$el.height() - @header.height() - 30)
    cb()
    $(window).resize cb
    $(document).on 'keydown.usercanvasoverlay', null, {}, (evt) =>
      @close() if evt.which == 27
    setTimeout (=>
      cb()
      ), 400
    
    this

class @UserCanvasOverlayDimmer extends Backbone.View
  id: 'user-canvas-overlay-dimmer'
  events:
    'click': 'click'
  click: ->
    @trigger 'close'
    return false;