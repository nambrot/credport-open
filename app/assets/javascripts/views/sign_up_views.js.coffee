class @SignupOverlayView extends Backbone.View
  className: 'signup-overlay-view'
  model: User
  template: _.template("
    <div class='row'>
      <div class='ten columns centered'>
        <h5><%= I18n.t('overlay_views.signup.subtitle', {name: name.split(' ')[0]} ) %></h5>
        <p><%= I18n.t('overlay_views.signup.incentive', {name: name.split(' ')[0]} ) %></p>
      </div>
    </div>
    <div class='row' style='margin-bottom:25px;'>
      <div class='signup-login six columns centered'>
        <a href='/auth/facebook?origin=/u/<%= id %>' class='button facebook rounded' id='facebook-signup'>
          <div class='icon-button facebook-icon'></div>
          <span>#{I18n.t('signup.with_facebook')}</span>
        </a>
        <a href='/auth/linkedin?origin=/u/<%= id %>' class='button linkedin rounded' id='linkedin-signup'>
          <div class='icon-button linkedin-icon'></div>
          <span>#{I18n.t('signup.with_linkedin')}</span>
        </a>
        <a href='/auth/twitter?origin=/u/<%= id %>' class='button twitter rounded' id='twitter-signup'>
          <div class='icon-button twitter-icon'></div>
          <span>#{I18n.t('signup.with_twitter')}</span>
        </a>
        <a href='/signup'>#{I18n.t('signup.with_email')}</a>
      </div>
    </div>
  ")
  header: "
    <h2>#{I18n.t('overlay_views.signup.title')}</h2>
  "
  render: ->
    @$el.html(@template(@model.toJSON()))
    this