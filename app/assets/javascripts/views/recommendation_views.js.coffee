class @RecommendationRequestToApproveView extends Backbone.View
  model: Recommendation
  tagName: 'li'
  events:
    'click .approve': 'approve'
    'click .delete': 'delete'
  approve: ->
    $.ajax
      type: 'PUT'
      dataType: 'json'
      url: "/u/#{@model.collection.user.get('id')}/reviews/#{@model.get('id')}/approve.json"
      success: (resp) =>
        @model.collection.user.reviews().add resp
        @model.collection.remove @model
        $.gritter.add
          title: I18n.t('Success')
          text: I18n.t('rec_approved')
      error: (arg1, arg2, arg3) ->
        $.gritter.add
          title: I18n.t 'Error'
          text: JSON.parse(arg1.responseText).errors.join(' ')
    return false
  delete: ->
    $.ajax
      type: 'DELETE'
      dataType: 'json'
      url: "/u/#{@model.collection.user.get('id')}/reviews/#{@model.get('id')}.json"
      success: (resp) =>
        @model.collection.remove @model
        $.gritter.add
          title: I18n.t('Success')
          text: I18n.t('rec_deleted')
      error: (arg1, arg2, arg3) ->
        $.gritter.add
          title: I18n.t 'Error'
          text: JSON.parse(arg1.responseText).errors.join(' ')
    return false
  template: _.template("
    <p><%= model.attributes.recommender.name %> #{I18n.t('rec_descrip1')} <%= model.get_relationship() %> #{I18n.t('rec_descrip2')}</p>
    <blockquote><%= model.attributes.text %></blockquote>
    <a href='' class='button rounded approve'>#{I18n.t('Approve')}</a>
    <a href='' class='button rounded delete'>#{I18n.t('Delete')}</a>  
    ")
  render: ->
    @$el.html @template model: @model
    this
class @RecommendationRequestOverlayView extends Backbone.View
  model: User
  id: 'recommendation-request-overlay'
  header: "
    <h2>#{I18n.t('overlay_views.recommendation_request.title')}</h2>
    <p>#{I18n.t('overlay_views.recommendation_request.subtitle')}</p>
    "
  events:
    'submit #requestRecommendationForm': 'requestByEmail'
  requestByEmail: ->
    $.post "/u/#{@model.get('id')}/reviews/request_by_email", {emails: $('#requestRecommendationForm #emails').val(), message: $('#requestRecommendationForm #email_text').val()}, =>
      $.gritter.add
        title: I18n.t('Success')
        text: I18n.t('Emails sent')
    .error (arg1) ->
      $.gritter.add
        title: I18n.t('Error')
        text: JSON.parse(arg1.responseText).errors.join(' ')
    return false
  template: _.template("
    <h4><%= I18n.t('overlay_views.recommendation_request.review_paragraph', {count: reviews.length}) %></h4>

    <h5>#{I18n.t('ask_headline')}</h5>
      <p>#{I18n.t('ask_p')} <a href='<%= model.get('url') + '/writeRecommendation' %>'><%= model.get('url') + '/writeRecommendation' %></a> #{I18n.t('ask_p2')}</p>
      <p>
        <a href='https://www.facebook.com/dialog/feed?app_id=339403882822622&link=<%= encodeURIComponent(model.get('url') + '/writeRecommendation') %>&name=Write%20me%20a%20Recommendation%20on%20Credport&redirect_uri=<%= encodeURIComponent(model.get('url')) %>' class='button facebook' target='_blank'  id='facebook-signup'>
          <span>#{I18n.t('ask_fbook')}</span>
        </a>
      <a href='http://twitter.com/share?url=<%= encodeURIComponent(model.get('url') + '/writeRecommendation') %>&related=credport&text=Write%20me%20a%20recommendation%20on%20Credport' class='button twitter' target='_blank'>#{I18n.t('ask_twitter')}</a></p>

    <form id='requestRecommendationForm'>
      <h5>#{I18n.t('ask_email')}</h5>
      <label for='emails'>#{I18n.t('ask_email1')}</label>
      <input name='' id='emails' type='text'/>
      <label for='email_text'>#{I18n.t('ask_email2')}</label>
      <textarea name='' id='email_text' placeholder='Please write me a recommendation on Credport'></textarea>
      <input type='submit' class='button' value='Send Emails'>
    </form>

    <% if(recommendations.length > 0){ %>
      <h4>You currently have <%= recommendations.length %> Recommendations to approve</h4>
      <ul id='recommendations-to-approve-list'></ul>
    <% } %>


    ")
  initialize: ->
    @reviews = @model.reviews()
    @reviews.on 'reset add remove', @render, this
    @recommendations_to_approve = @model.recommendations_to_approve()
    @recommendations_to_approve.on 'reset add remove', @render, this
  render: ->
    @$el.html @template model: @model, reviews: @reviews, recommendations: @recommendations_to_approve
    if @recommendations_to_approve.length > 0
      ul = @$ '#recommendations-to-approve-list'
      for recommendation in @recommendations_to_approve.models
        view = new RecommendationRequestToApproveView model: recommendation
        ul.append view.render().el
    this
    
class @RecommendationWriteOverlayView extends Backbone.View
  model: User
  id: 'recommendation-write-overlay'
  recommendation: null
  events:
    'submit #recommendation_form': 'submit'
    'submit #recommendation_update_form': 'update'
  relationship_context_mapping:
    'credport_friend_recommendation': 'friend'
    'credport_colleague_recommendation': 'colleague'
    'credport_family_recommendation': 'family'
    'credport_other_recommendation': 'other'
  update: (evt) ->
    $.ajax
      type: 'PUT'
      dataType: 'json'
      url: "/u/#{@model.get('id')}/review.json"
      data:
        recommendation_text: @$('#recommendation_text').val()
        relationship: @$('#recommendation_relationship').val()
      success: (resp) =>
        @recommendation.set role: "credport_#{@$('#recommendation_relationship').val()}_recommendation", text: @$('#recommendation_text').val()
        $.gritter.add
          title: I18n.t 'Success'
          text: "Recommendation successfully updated"
      error: (arg1, arg2, arg3) ->
        $.gritter.add
          title: I18n.t 'Error'
          text: JSON.parse(arg1.responseText).errors.join(' ')
    return false
  submit: (evt) ->
    $.post("/u/#{@model.get('id')}/reviews.json", {recommendation_text: @$('#recommendation_text').val(), relationship: @$('#recommendation_relationship') .val()}, (resp) =>
          @recommendation = new Recommendation resp, user: @model
          @render()
          $.gritter.add
            title: 'Success'
            text: "You successfully recommended #{@model.first_name()}. Once he/she approves, it will be visible on his/her profile."
    ).error (arg1, arg2, arg3) ->
      $.gritter.add
        title: I18n.t 'Error'
        text: JSON.parse(arg1.responseText).errors.join(' ')
    return false
  
  header: "
    <h2>#{I18n.t('overlay_views.recommendation_new.title')}</h2>
    <p>#{I18n.t('overlay_views.recommendation_new.subtitle')}</p>
    "
  template: _.template("
      <p><%= model.first_name() %> #{I18n.t('write_p')}</p>
      <h4>#{I18n.t('write_h4')}</h4>
      <form action='' id='recommendation_form'>
        <ul>#{I18n.t('write_list')}
          <li>#{I18n.t('write_list1')}<%= model.first_name() %></li>
          <li>#{I18n.t('write_list2')}<%= model.first_name() %>?</li>
          <li>#{I18n.t('write_list3')}</li>
        </ul>
        <p>
          #{I18n.t('write_prompt')}
          <select name='relationship' id='recommendation_relationship'>
            <option value='friend'>#{I18n.t('write_prompt1')}</option>
            <option value='colleague'>#{I18n.t('write_prompt2')}</option>
            <option value='family'>#{I18n.t('write_prompt3')}</option>
            <option value='other'>#{I18n.t('write_prompt4')}</option>
          </select>
          #{I18n.t('write_prompt5')} <%= model.first_name() %>
          #{I18n.t('write_prompt6')}
        </p>
        <textarea name='' id='recommendation_text' placeholder='<%= model.first_name() %> is awesome'></textarea>
        <input type='submit' class='button' value='Submit Recommendation'>
      </form>
    ")
  notsignedin_template: _.template("
    <p><%= model.first_name() %> #{I18n.t('write_p')}</p>
    <h4>#{I18n.t('write_nosign')}</h4>
    <p>#{I18n.t('write_nosign1')}<a href='/'>learn more.</a></p>
    <div class='row' style='margin-bottom:25px;'>
      <div class='signup-login six columns centered'>
        <a href='/auth/facebook' class='button facebook rounded' id='facebook-signup'>
          <div class='icon-button facebook-icon'></div>
          <span>#{I18n.t('signup.with_facebook')}</span>
        </a>
        <a href='/auth/linkedin' class='button linkedin rounded' id='linkedin-signup'>
          <div class='icon-button linkedin-icon'></div>
          <span>#{I18n.t('signup.with_linkedin')}</span>
        </a>
        <a href='/auth/twitter' class='button twitter rounded' id='twitter-signup'>
          <div class='icon-button twitter-icon'></div>
          <span>#{I18n.t('signup.with_twitter')}</span>
        </a>
        <a href='/signup'>#{I18n.t('signup.with_email')}</a>
      </div>
    </div>
  ")
  recommendation_template: _.template("
    <h4>#{I18n.t('write_h4')}</h4>
    <p>#{I18n.t('write_finished')}</p>
    <form action='' id='recommendation_update_form'>
      <p>
        #{I18n.t('write_prompt')}
        <select name='relationship' id='recommendation_relationship'>
          <option value='friend'>#{I18n.t('write_prompt1')}</option>
          <option value='colleague'>#{I18n.t('write_prompt2')}</option>
          <option value='family'>#{I18n.t('write_prompt3')}</option>
          <option value='other'>#{I18n.t('write_prompt4')}</option>
        </select>
        #{I18n.t('write_prompt5')} <%= model.first_name() %>
        #{I18n.t('write_prompt6')}
      </p>
      <textarea name='' id='recommendation_text' placeholder='Some kind words'><%= recommendation.attributes.text %></textarea>
      <input type='submit' class='button' value='Update Recommendation'>
    </form>
  ")
  initialize: (options) ->
    $.get "/u/#{@model.get('id')}/review.json", (resp) =>
      @recommendation = new Recommendation resp, user: @model
      @recommendation.on 'change', @render, this
      @render()
    @current_user = options.current_user
  render: ->
    if @current_user?
      if @recommendation?
        @$el.html @recommendation_template model: @model, recommendation: @recommendation
        @$("#recommendation_relationship option[value='#{@relationship_context_mapping[@recommendation.attributes.role]}']").attr('selected', true)
      else
        @$el.html @template model: @model
    else
      @$el.html @notsignedin_template model: @model 
      mixpanel.track_links('#facebook-signup', 'Sign Up Init', {provider: 'facebook', source: 'writeRec'});
      mixpanel.track_links('#twitter-signup', 'Sign Up Init', {provider: 'twitter', source: 'writeRec'});
      mixpanel.track_links('#linkedin-signup', 'Sign Up Init', {provider: 'linkedin', source: 'writeRec'});
