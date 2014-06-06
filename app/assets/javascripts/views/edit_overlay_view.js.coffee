class @EmailEditOverlaySubView extends Backbone.View
  model: User
  tagName: 'li'
  template: _.template("
      <div class='title'>
        <h5>#{I18n.t('edit_overlay.email.title.h5')} <%= title_append %></h5>
        <p>#{I18n.t('edit_overlay.email.title.p')}</p>
      </div>
      <div class='content'>
        <form id='addEmail'>
        <h5>#{I18n.t('edit_overlay.email.add.h5')}</h5>
        <input type='text' id='email_input' placeholder='connor@credport.org'/>
        <button type='submit' class='button'>#{I18n.t('edit_overlay.email.add.button')}</button>
        </form>
      </div>
    ")
  emailsToVerifyTemplate: "
    <div id='emails_to_verify'>
      <h5>#{I18n.t('edit_overlay.email.to_verify.h5')}</h5>
      <ul></ul>
      <h5>#{I18n.t('edit_overlay.email.verify.h5')}</h5>
      <form id='verifyemail'>
        <input type='text' id='email_code' placeholder='#{I18n.t('edit_overlay.email.verify.placeholder')}' />
        <button type='submit' class='button'>#{I18n.t('edit_overlay.email.verify.button')}</button>
      </form>
    </div>
  "
  events: 
    'submit #addEmail': 'submitEmail'
    'submit #verifyemail': 'verifyEmail'
    'click .title': 'toggleAccordion'
  toggleAccordion: (evt) ->
    mixpanel.track "Profile:Edit:Email:Toggle"
    mixpanel.people.increment "Profile:Edit:Email:Toggle"
  submitEmail: (evt) ->
    $.post("/u/#{@model.get('id')}/emails", email: $("#email_input").val(), null, 'json')
      .success (resp) =>
        $("#email_input").val('')
        $.gritter.add
          title: I18n.t('Success')
          #TODO: I18n
          text: resp.success
        @emails_to_verify.add resp.email
      .error (xhr, state, error) ->
        $.gritter.add 
          title: I18n.t('Error')
          text: I18n.t("Something went wrong")
    return false
  verifyEmail: ->
    $.get("/verify/email/#{$('#email_code').val()}", {}, null, 'json')
      .success (resp) =>
        $.gritter.add
          title: I18n.t('Success')
          #TODO: I18n
          text: resp.success
        email = @emails_to_verify.where email: resp.email.email
        @emails_to_verify.remove email
        @model.verifications (verifications) ->
          verifications.add resp.verification
      .error (xhr, state, error) ->
        resp = JSON.parse xhr.responseText
        $.gritter.add 
          title: I18n.t('Error')
          #TODO I18n
          text: "#{resp.errors}"
    return false
  add_emails_to_verify: (emails) ->
    @emails_to_verify.add emails
  initialize: ->
    @emails_to_verify = new Emails()
    @emails_to_verify.on 'add', @render, this
  render: ->
    @$el.html(@template({
      title_append: I18n.t('edit_overlay.email.to_verify.title_append', count: @emails_to_verify.length)
    }))
    if @emails_to_verify.length > 0
      
      emails_to_verify_view = $ @emailsToVerifyTemplate
      emails_to_verify_ul = emails_to_verify_view.find 'ul'

      for email in @emails_to_verify.models
        emails_to_verify_ul.append (new EmailView(model: email)).render().el

      @$('.content').append emails_to_verify_view
    this

class @PhoneEditOverlaySubView extends Backbone.View
  model: User
  tagName: 'li'
  template: _.template("
      <div class='title'>
        <h5>#{I18n.t('edit_overlay.phone.title.h5')} <%= title_append %></h5>
        <p>#{I18n.t('edit_overlay.phone.title.p')}</p>
      </div>
      <div class='content'>
        <h5>#{I18n.t('edit_overlay.phone.add.h5')}</h5>
        <form id='addPhone'>
          <label>#{I18n.t('edit_overlay.phone.add.country')}</label>
          <select id='phone_country' name='phone_country'><option value='93' data-prefix='93' id='Afghanistan'>Afghanistan</option><option value='355' data-prefix='355' id='Albania'>Albania</option><option value='213' data-prefix='213' id='Algeria'>Algeria</option><option value='1' data-prefix='1' id='American Samoa'>American Samoa</option><option value='376' data-prefix='376' id='Andorra'>Andorra</option><option value='244' data-prefix='244' id='Angola'>Angola</option><option value='1' data-prefix='1' id='Anguilla'>Anguilla</option><option value='1' data-prefix='1' id='Antigua and Barbuda'>Antigua and Barbuda</option><option value='54' data-prefix='54' id='Argentina'>Argentina</option><option value='374' data-prefix='374' id='Armenia'>Armenia</option><option value='297' data-prefix='297' id='Aruba'>Aruba</option><option value='61' data-prefix='61' id='Australia'>Australia</option><option value='43' data-prefix='43' id='Austria'>Austria</option><option value='994' data-prefix='994' id='Azerbaijan'>Azerbaijan</option><option value='1' data-prefix='1' id='Bahamas'>Bahamas</option><option value='973' data-prefix='973' id='Bahrain'>Bahrain</option><option value='880' data-prefix='880' id='Bangladesh'>Bangladesh</option><option value='1' data-prefix='1' id='Barbados'>Barbados</option><option value='375' data-prefix='375' id='Belarus'>Belarus</option><option value='32' data-prefix='32' id='Belgium'>Belgium</option><option value='501' data-prefix='501' id='Belize'>Belize</option><option value='229' data-prefix='229' id='Benin'>Benin</option><option value='1' data-prefix='1' id='Bermuda'>Bermuda</option><option value='975' data-prefix='975' id='Bhutan'>Bhutan</option><option value='591' data-prefix='591' id='Bolivia'>Bolivia</option><option value='387' data-prefix='387' id='Bosnia'>Bosnia</option><option value='267' data-prefix='267' id='Botswana'>Botswana</option><option value='55' data-prefix='55' id='Brazil'>Brazil</option><option value='246' data-prefix='246' id='British Indian Ocean Territory'>British Indian Ocean Territory</option><option value='673' data-prefix='673' id='Brunei Darussalam'>Brunei Darussalam</option><option value='359' data-prefix='359' id='Bulgaria'>Bulgaria</option><option value='226' data-prefix='226' id='Burkina Faso'>Burkina Faso</option><option value='257' data-prefix='257' id='Burundi'>Burundi</option><option value='590' data-prefix='590' id='Saint Barthélemy'>Saint Barthélemy</option><option value='855' data-prefix='855' id='Cambodia'>Cambodia</option><option value='237' data-prefix='237' id='Cameroon'>Cameroon</option><option value='1' data-prefix='1' id='Canada'>Canada</option><option value='238' data-prefix='238' id='Cape Verde'>Cape Verde</option><option value='1' data-prefix='1' id='Cayman Islands'>Cayman Islands</option><option value='236' data-prefix='236' id='Central African Republic'>Central African Republic</option><option value='235' data-prefix='235' id='Chad'>Chad</option><option value='56' data-prefix='56' id='Chile'>Chile</option><option value='86' data-prefix='86' id='China'>China</option><option value='61' data-prefix='61' id='Christmas Island'>Christmas Island</option><option value='61' data-prefix='61' id='Cocos (Keeling) Islands'>Cocos (Keeling) Islands</option><option value='57' data-prefix='57' id='Colombia'>Colombia</option><option value='269' data-prefix='269' id='Comoros'>Comoros</option><option value='242' data-prefix='242' id='Congo'>Congo</option><option value='682' data-prefix='682' id='Cook Islands'>Cook Islands</option><option value='506' data-prefix='506' id='Costa Rica'>Costa Rica</option><option value='225' ivoire'='' data-prefix='225' id='Cote D'>Cote D'ivoire</option><option value='385' data-prefix='385' id='Croatia'>Croatia</option><option value='53' data-prefix='53' id='Cuba'>Cuba</option><option value='357' data-prefix='357' id='Cyprus'>Cyprus</option><option value='420' data-prefix='420' id='Czech Republic'>Czech Republic</option><option value='45' data-prefix='45' id='Denmark'>Denmark</option><option value='253' data-prefix='253' id='Djibouti'>Djibouti</option><option value='1' data-prefix='1' id='Dominica'>Dominica</option><option value='1' data-prefix='1' id='Dominican Republic'>Dominican Republic</option><option value='593' data-prefix='593' id='Ecuador'>Ecuador</option><option value='20' data-prefix='20' id='Egypt'>Egypt</option><option value='503' data-prefix='503' id='El Salvador'>El Salvador</option><option value='240' data-prefix='240' id='Equatorial Guinea'>Equatorial Guinea</option><option value='291' data-prefix='291' id='Eritrea'>Eritrea</option><option value='372' data-prefix='372' id='Estonia'>Estonia</option><option value='251' data-prefix='251' id='Ethiopia'>Ethiopia</option><option value='500' data-prefix='500' id='Falkland Islands (Malvinas)'>Falkland Islands (Malvinas)</option><option value='298' data-prefix='298' id='Faroe Islands'>Faroe Islands</option><option value='679' data-prefix='679' id='Fiji'>Fiji</option><option value='358' data-prefix='358' id='Finland'>Finland</option><option value='33' data-prefix='33' id='France'>France</option><option value='594' data-prefix='594' id='French Guiana'>French Guiana</option><option value='689' data-prefix='689' id='French Polynesia'>French Polynesia</option><option value='241' data-prefix='241' id='Gabon'>Gabon</option><option value='220' data-prefix='220' id='Gambia'>Gambia</option><option value='995' data-prefix='995' id='Georgia'>Georgia</option><option value='49' data-prefix='49' id='Germany'>Germany</option><option value='233' data-prefix='233' id='Ghana'>Ghana</option><option value='350' data-prefix='350' id='Gibraltar'>Gibraltar</option><option value='30' data-prefix='30' id='Greece'>Greece</option><option value='299' data-prefix='299' id='Greenland'>Greenland</option><option value='1' data-prefix='1' id='Grenada'>Grenada</option><option value='590' data-prefix='590' id='Guadeloupe'>Guadeloupe</option><option value='1' data-prefix='1' id='Guam'>Guam</option><option value='502' data-prefix='502' id='Guatemala'>Guatemala</option><option value='224' data-prefix='224' id='Guinea'>Guinea</option><option value='245' data-prefix='245' id='Guinea-bissau'>Guinea-bissau</option><option value='592' data-prefix='592' id='Guyana'>Guyana</option><option value='509' data-prefix='509' id='Haiti'>Haiti</option><option value='504' data-prefix='504' id='Honduras'>Honduras</option><option value='852' data-prefix='852' id='Hong Kong'>Hong Kong</option><option value='36' data-prefix='36' id='Hungary'>Hungary</option><option value='354' data-prefix='354' id='Iceland'>Iceland</option><option value='91' data-prefix='91' id='India'>India</option><option value='62' data-prefix='62' id='Indonesia'>Indonesia</option><option value='98' data-prefix='98' id='Iran'>Iran</option><option value='964' data-prefix='964' id='Iraq'>Iraq</option><option value='353' data-prefix='353' id='Ireland'>Ireland</option><option value='972' data-prefix='972' id='Israel'>Israel</option><option value='39' data-prefix='39' id='Italy'>Italy</option><option value='1' data-prefix='1' id='Jamaica'>Jamaica</option><option value='81' data-prefix='81' id='Japan'>Japan</option><option value='962' data-prefix='962' id='Jordan'>Jordan</option><option value='7' data-prefix='7' id='Kazakhstan'>Kazakhstan</option><option value='254' data-prefix='254' id='Kenya'>Kenya</option><option value='686' data-prefix='686' id='Kiribati'>Kiribati</option><option value='82' data-prefix='82' id='South Korea'>South Korea</option><option value='965' data-prefix='965' id='Kuwait'>Kuwait</option><option value='996' data-prefix='996' id='Kyrgyzstan'>Kyrgyzstan</option><option value='856' data-prefix='856' id='Laos'>Laos</option><option value='371' data-prefix='371' id='Latvia'>Latvia</option><option value='961' data-prefix='961' id='Lebanon'>Lebanon</option><option value='266' data-prefix='266' id='Lesotho'>Lesotho</option><option value='231' data-prefix='231' id='Liberia'>Liberia</option><option value='218' data-prefix='218' id='Libya'>Libya</option><option value='423' data-prefix='423' id='Liechtenstein'>Liechtenstein</option><option value='370' data-prefix='370' id='Lithuania'>Lithuania</option><option value='352' data-prefix='352' id='Luxembourg'>Luxembourg</option><option value='382' data-prefix='382' id='Montenegro'>Montenegro</option><option value='853' data-prefix='853' id='Macau'>Macau</option><option value='389' data-prefix='389' id='Macedonia'>Macedonia</option><option value='261' data-prefix='261' id='Madagascar'>Madagascar</option><option value='265' data-prefix='265' id='Malawi'>Malawi</option><option value='60' data-prefix='60' id='Malaysia'>Malaysia</option><option value='960' data-prefix='960' id='Maldives'>Maldives</option><option value='223' data-prefix='223' id='Mali'>Mali</option><option value='356' data-prefix='356' id='Malta'>Malta</option><option value='692' data-prefix='692' id='Marshall Islands'>Marshall Islands</option><option value='596' data-prefix='596' id='Martinique'>Martinique</option><option value='222' data-prefix='222' id='Mauritania'>Mauritania</option><option value='230' data-prefix='230' id='Mauritius'>Mauritius</option><option value='262' data-prefix='262' id='Mayotte'>Mayotte</option><option value='52' data-prefix='52' id='Mexico'>Mexico</option><option value='691' data-prefix='691' id='Micronesia'>Micronesia</option><option value='373' data-prefix='373' id='Moldova'>Moldova</option><option value='377' data-prefix='377' id='Monaco'>Monaco</option><option value='976' data-prefix='976' id='Mongolia'>Mongolia</option><option value='1' data-prefix='1' id='Montserrat'>Montserrat</option><option value='212' data-prefix='212' id='Morocco'>Morocco</option><option value='258' data-prefix='258' id='Mozambique'>Mozambique</option><option value='95' data-prefix='95' id='Myanmar'>Myanmar</option><option value='264' data-prefix='264' id='Namibia'>Namibia</option><option value='674' data-prefix='674' id='Nauru'>Nauru</option><option value='977' data-prefix='977' id='Nepal'>Nepal</option><option value='31' data-prefix='31' id='Netherlands'>Netherlands</option><option value='599' data-prefix='599' id='Netherlands Antilles'>Netherlands Antilles</option><option value='687' data-prefix='687' id='New Caledonia'>New Caledonia</option><option value='64' data-prefix='64' id='New Zealand'>New Zealand</option><option value='505' data-prefix='505' id='Nicaragua'>Nicaragua</option><option value='227' data-prefix='227' id='Niger'>Niger</option><option value='234' data-prefix='234' id='Nigeria'>Nigeria</option><option value='683' data-prefix='683' id='Niue'>Niue</option><option value='672' data-prefix='672' id='Norfolk Island'>Norfolk Island</option><option value='1' data-prefix='1' id='Northern Mariana Islands'>Northern Mariana Islands</option><option value='47' data-prefix='47' id='Norway'>Norway</option><option value='968' data-prefix='968' id='Oman'>Oman</option><option value='92' data-prefix='92' id='Pakistan'>Pakistan</option><option value='680' data-prefix='680' id='Palau'>Palau</option><option value='507' data-prefix='507' id='Panama'>Panama</option><option value='675' data-prefix='675' id='Papua New Guinea'>Papua New Guinea</option><option value='595' data-prefix='595' id='Paraguay'>Paraguay</option><option value='51' data-prefix='51' id='Peru'>Peru</option><option value='63' data-prefix='63' id='Philippines'>Philippines</option><option value='48' data-prefix='48' id='Poland'>Poland</option><option value='351' data-prefix='351' id='Portugal'>Portugal</option><option value='1' data-prefix='1' id='Puerto Rico'>Puerto Rico</option><option value='974' data-prefix='974' id='Qatar'>Qatar</option><option value='262' data-prefix='262' id='Reunion'>Reunion</option><option value='40' data-prefix='40' id='Romania'>Romania</option><option value='381' data-prefix='381' id='Serbia'>Serbia</option><option value='7' data-prefix='7' id='Russian Federation'>Russian Federation</option><option value='250' data-prefix='250' id='Rwanda'>Rwanda</option><option value='1' data-prefix='1' id='Saint Kitts and Nevis'>Saint Kitts and Nevis</option><option value='1' data-prefix='1' id='Saint Lucia'>Saint Lucia</option><option value='1' data-prefix='1' id='Saint Vincent and The Grenadines'>Saint Vincent and The Grenadines</option><option value='685' data-prefix='685' id='Samoa'>Samoa</option><option value='378' data-prefix='378' id='San Marino'>San Marino</option><option value='239' data-prefix='239' id='Sao Tome and Principe'>Sao Tome and Principe</option><option value='966' data-prefix='966' id='Saudi Arabia'>Saudi Arabia</option><option value='221' data-prefix='221' id='Senegal'>Senegal</option><option value='248' data-prefix='248' id='Seychelles'>Seychelles</option><option value='232' data-prefix='232' id='Sierra Leone'>Sierra Leone</option><option value='65' data-prefix='65' id='Singapore'>Singapore</option><option value='421' data-prefix='421' id='Slovakia'>Slovakia</option><option value='386' data-prefix='386' id='Slovenia'>Slovenia</option><option value='677' data-prefix='677' id='Solomon Islands'>Solomon Islands</option><option value='252' data-prefix='252' id='Somalia'>Somalia</option><option value='27' data-prefix='27' id='South Africa'>South Africa</option><option value='34' data-prefix='34' id='Spain'>Spain</option><option value='94' data-prefix='94' id='Sri Lanka'>Sri Lanka</option><option value='290' data-prefix='290' id='St. Helena'>St. Helena</option><option value='508' data-prefix='508' id='St. Pierre and Miquelon'>St. Pierre and Miquelon</option><option value='249' data-prefix='249' id='Sudan'>Sudan</option><option value='597' data-prefix='597' id='Suriname'>Suriname</option><option value='47' data-prefix='47' id='Svalbard and Jan Mayen Islands'>Svalbard and Jan Mayen Islands</option><option value='268' data-prefix='268' id='Swaziland'>Swaziland</option><option value='46' data-prefix='46' id='Sweden'>Sweden</option><option value='41' data-prefix='41' id='Switzerland'>Switzerland</option><option value='963' data-prefix='963' id='Syrian Arab Republic'>Syrian Arab Republic</option><option value='886' data-prefix='886' id='Taiwan'>Taiwan</option><option value='992' data-prefix='992' id='Tajikistan'>Tajikistan</option><option value='255' data-prefix='255' id='Tanzania'>Tanzania</option><option value='66' data-prefix='66' id='Thailand'>Thailand</option><option value='228' data-prefix='228' id='Togo'>Togo</option><option value='690' data-prefix='690' id='Tokelau'>Tokelau</option><option value='676' data-prefix='676' id='Tonga'>Tonga</option><option value='1' data-prefix='1' id='Trinidad and Tobago'>Trinidad and Tobago</option><option value='216' data-prefix='216' id='Tunisia'>Tunisia</option><option value='90' data-prefix='90' id='Turkey'>Turkey</option><option value='993' data-prefix='993' id='Turkmenistan'>Turkmenistan</option><option value='1' data-prefix='1' id='Turks and Caicos Islands'>Turks and Caicos Islands</option><option value='688' data-prefix='688' id='Tuvalu'>Tuvalu</option><option value='256' data-prefix='256' id='Uganda'>Uganda</option><option value='380' data-prefix='380' id='Ukraine'>Ukraine</option><option value='971' data-prefix='971' id='United Arab Emirates'>United Arab Emirates</option><option value='44' data-prefix='44' id='United Kingdom'>United Kingdom</option><option value='1' data-prefix='1' selected='selected' id='United States'>United States</option><option value='598' data-prefix='598' id='Uruguay'>Uruguay</option><option value='998' data-prefix='998' id='Uzbekistan'>Uzbekistan</option><option value='678' data-prefix='678' id='Vanuatu'>Vanuatu</option><option value='379' data-prefix='379' id='Vatican City State'>Vatican City State</option><option value='58' data-prefix='58' id='Venezuela'>Venezuela</option><option value='84' data-prefix='84' id='Vietnam'>Vietnam</option><option value='1' data-prefix='1' id='Virgin Islands (British)'>Virgin Islands (British)</option><option value='1' data-prefix='1' id='Virgin Islands (U.S.)'>Virgin Islands (U.S.)</option><option value='681' data-prefix='681' id='Wallis and Futuna Islands'>Wallis and Futuna Islands</option><option value='967' data-prefix='967' id='Yemen'>Yemen</option><option value='260' data-prefix='260' id='Zambia'>Zambia</option><option value='263' data-prefix='263' id='Zimbabwe'>Zimbabwe</option></select>
          <label>#{I18n.t('edit_overlay.phone.add.number')}</label>
          
          <div class='row collapse'>
            <div class='two mobile-one columns'>
              <span class='prefix' id='phone_prefix'>+1</span>
            </div>
            <div class='ten mobile-three columns'>
              <input type='text' id='phone_input' placeholder='6173532000'/>
            </div>
          </div>
          
          <button type='submit' class='button'>#{I18n.t('edit_overlay.phone.add.button')}</button>
        </form>
      </div>
    ")
  phonesToVerifyTemplate: ("
    <div>
      <h5>#{I18n.t('edit_overlay.phone.to_verify.h5')}</h5>
      <ul></ul>
      <form id='verifyphone'>
      <h5>#{I18n.t('edit_overlay.phone.verify.h5')}</h5>
        <input type='text' id='phone_code' placeholder=#{I18n.t('edit_overlay.email.verify.placeholder')} />
        <button type='submit' class='button'>#{I18n.t('edit_overlay.email.verify.button')}</button>
      </form>
    </div>
    ")
  events:
    'submit #addPhone': 'submitPhone'
    'submit #verifyphone': 'verifyPhone'
    'change #addPhone': 'selectCountry'
    'click .title': 'toggleAccordion'
  toggleAccordion: (evt) ->
    mixpanel.track "Profile:Edit:Phone:Toggle"
    mixpanel.people.increment "Profile:Edit:Phone:Toggle"
  submitPhone: ->
    # TODO: offer choice between text/call verification
    $.post("/u/#{@model.get('id')}/phones", {phone: $("#phone_input").val(), country: $("#phone_country").val()}, null, 'json')
      .success (resp) =>
        $("#phone_input").val('')
        $.gritter.add
          title: I18n.t('Success')
          #TODO: i18n
          text: resp.success
        @phones_to_verify.add resp.phone
      .error (xhr, state, error) =>
        resp = JSON.parse xhr.responseText
        $.gritter.add 
          title: I18n.t('Error')
          text: I18n.t("Something went wrong")
    return false
  verifyPhone: ->
    $.get("/verify/phone/#{$('#phone_code').val()}", {}, null, 'json')
      .success (resp) =>
        $.gritter.add
          title: I18n.t('Success')
          #TODO: i18n
          text: resp.success
        phone = @phones_to_verify.where phone: resp.phone.phone
        @phones_to_verify.remove phone
        @model.verifications (verifications) ->
          verifications.add resp.verification
      .error (xhr, state, error) ->
        resp = JSON.parse xhr.responseText
        $.gritter.add 
          title: I18n.t('Error')
          #TODO: i18n
          text: "#{resp.errors}"
    return false
  add_phones_to_verify: (phones) ->
    @phones_to_verify.add phones
  setCountry: (callback) ->
    if @country
      option = @$("#" + @country)
      if option.length > 0
        @$("#phone_country").val @country
        @selectCountry()  
    else
      @getCountry =>
        option = @$("#" + @country)
        if option.length > 0
          @$("#phone_country").val @country
          @selectCountry()
  getCountry: (callback) ->
    $.get '/utility/country', (resp) =>
      @country = resp.country
      if callback?
        callback()
  selectCountry: ->
    @$('#phone_prefix').text('+' + @$('#phone_country option:selected').data('prefix'))
  initialize: ->
    @phones_to_verify = new Phones()
    @phones_to_verify.on 'add', @render, this
  render: ->
    @$el.html(@template({
      title_append: I18n.t('edit_overlay.phone.to_verify.title_append', count: @phones_to_verify.length)
    }))
    if @phones_to_verify.length > 0
      
      phones_to_verify_view = $ @phonesToVerifyTemplate
      phones_to_verify_ul = phones_to_verify_view.find 'ul'

      for phone in @phones_to_verify.models
        phones_to_verify_ul.append (new PhoneView(model: phone)).render().el

      @$('.content').append phones_to_verify_view
    this

class @WebsiteEditOverlaySubView extends Backbone.View
  model: User
  tagName: 'li'
  template: _.template("
    <div class='title'>
      <h5>#{I18n.t('edit_overlay.webpage.title.h5')} <%= title_append %></h5>
      <p'>#{I18n.t('edit_overlay.webpage.title.p')}</p>
    </div>
    <div class='content'>
      <form id='addWebsite'>
        <h5>#{I18n.t('edit_overlay.webpage.add.h5')}</h5>
        <input type='text' id='website_url' placeholder='URL: http://www.credport.org'/>
        <input type='text' id='website_title' placeholder='Descripton: My Blog, etc'/>
        <button type='submit' class='button'>#{I18n.t('edit_overlay.webpage.add.button')}</button>
      </form>
    </div>
    ")
  websitesToVerifyTemplate: "
  <div>
    <h5>#{I18n.t('edit_overlay.webpage.to_verify.h5')}</h5>
    <p>#{I18n.t('edit_overlay.webpage.to_verify.p')}</p>
    <ul></ul>
  </div>
    "
  events:
    'submit #addWebsite': 'submitWebsite'
    'click .title': 'toggleAccordion'
  toggleAccordion: (evt) ->
    mixpanel.track "Profile:Edit:Website:Toggle"
    mixpanel.people.increment "Profile:Edit:Website:Toggle"
  submitWebsite: ->
    $.post("/u/#{@model.get('id')}/websites", website: { title: $("#website_title").val(), url: $('#website_url').val()  } , null, 'json')
      .success (resp) =>
        $("#website_title").val('')
        $("#website_url").val('')
        $.gritter.add
          title: I18n.t('Success')
          #TODO: I18n
          text: I18n.t('edit_overlay.webpage.success.notification', {verification_code: resp.website.verification_code})
        @websites_to_verify.add resp.website
      .error (xhr, state, error) ->
        $.gritter.add 
          title: I18n.t('Error')
          text: I18n.t("Something went wrong")
    return false
  add_websites_to_verify: (websites) ->
    @websites_to_verify.add websites
  initialize: ->
    @websites_to_verify = new Websites()
    @websites_to_verify.user = @model
    @websites_to_verify.on 'add', @render, this
  render: ->
    @$el.html(@template({
      title_append: I18n.t('edit_overlay.webpage.to_verify.title_append', count: @websites_to_verify.length)
    }))
    if @websites_to_verify.length > 0
      websites_to_verify_view = $ @websitesToVerifyTemplate
      websites_to_verify_ul = websites_to_verify_view.find 'ul'

      for website in @websites_to_verify.models
        websites_to_verify_ul.append (new WebsiteView(model: website)).render().el

      @$('.content').append websites_to_verify_view
    this

class @VerificationEditOverlayView extends Backbone.View
  model: User
  template: _.template("
    <h3>#{I18n.t('veri_overlay.h3')}</h3>
    <p>#{I18n.t('veri_overlay.p')}</p>
    <ul class='accordion'></ul>
    ")
  render: ->
    @$el.html(@template(@model.toJSON()))

    emailview = new EmailEditOverlaySubView model: @model
    @$('ul').append emailview.render().el

    phoneview = new PhoneEditOverlaySubView model: @model
    @$('ul').append phoneview.render().el
    
    websiteview = new WebsiteEditOverlaySubView model: @model
    @$('ul').append websiteview.render().el

    $.get "/utility/verifieds", (resp) =>
      emailview.add_emails_to_verify resp.emails
      phoneview.add_phones_to_verify resp.phones
      websiteview.add_websites_to_verify resp.websites

    this

class @NetworksEditOverlayView extends Backbone.View
  model: User
  events:
    'click #verifynetworks a': 'addNetwork'
  addNetwork: (evt) ->
    $.gritter.add 
      #TODO: I18n
      text: "Authenticating #{evt.currentTarget.innerText}"
      title: I18n.t('Redirecting')
    mixpanel.track('Init Network', {provider: evt.currentTarget.innerText})
    mixpanel.people.increment('Init Network')
    mixpanel.people.increment("Init Network #{evt.currentTarget.innerText}")
    setTimeout (->
      window.location = evt.currentTarget.href), 300
    return false
  template: "
    <div id='textarea' class='seven columns'>
      <h4>#{I18n.t('UPDATE OR ADD NETWORK')}</h4>
      <p style='font-size:17px;'>#{I18n.t('Add_verifications')}</p>
      <p style='font-size:17px;'><a href='/howitworks'>#{I18n.t('How it works')}</a></p>
    </div>
    <div class='signup-login four columns'><a href='/auth/facebook' class='button'><div class='facebook-icon icon-button'></div>Facebook</a>
      <a href='/auth/twitter' class='button'><div class='twitter-icon icon-button'></div>Twitter</a>
      <a href='/auth/linkedin' class='button'><div class='linkedin-icon icon-button'></div>Linkedin</a>
      <a href='/auth/xing' class='button'><div class='xing-icon icon-button'></div>Xing</a>
      <a href='/auth/ebay' class='button'><div class='ebay-icon icon-button'></div>eBay</a>
      <a href='/auth/paypal' class='button'><div class='paypal-icon icon-button'></div>PayPal</a>
    </div>
  "
  render: ->
    @$el.html @template
    this

class @PersonalEditOverlayView extends Backbone.View
  model: User
  events:
    'submit #namechange': 'change_name'
    'submit #taglinechange': 'change_tagline'
    'keypress #changed_tagline': 'on_tagline_change'
  template: _.template("
    <h3>#{I18n.t('person_overlay.h3')}</h3>
    <p>#{I18n.t('person_overlay.p')}</p>
    <p>
      <form id='namechange' action='/u/<%= model.get('id') %>/name' method='post'>
        <label for='changed_name'><h5>#{I18n.t('person_overlay.name.h5')}</h5></label>
        <input type='text' id='changed_name' value='<%= model.get('name') %>' />
        <input type='submit' class='button' value='#{I18n.t('person_overlay.name.button')}''>
      </form>
    </p>
    <p>
      <form id='taglinechange' action='/u/<%= model.get('id') %>/tagline' method='post'>
        <label for='changed_tagline'><h5>#{I18n.t('person_overlay.tagline.h5')}</h5></label>
        <textarea id='changed_tagline' placeholder='#{I18n.t('person_overlay.tagline.placeholder')}'><%= model.get('tagline') %></textarea>
        <input type='submit' class='button' value='#{I18n.t('person_overlay.tagline.button')}'>
      </form>
    </p>
    
  ")
  on_tagline_change: ->
    if @$('#changed_tagline').height() < @$('#changed_tagline')[0].scrollHeight
      @$('#changed_tagline').css('height', @$('#changed_tagline')[0].scrollHeight) if @$('#changed_tagline')[0].scrollHeight > 50
  change_tagline: ->
    $.post("/u/#{@model.get('id')}/tagline", tagline: $("#changed_tagline").val(), null, 'json')
      .success (resp) =>
        @model.set resp
        $.gritter.add
          title: I18n.t('Success')
          text: I18n.t('tagline_change', {tagline: @model.escape('tagline')})
      .error (xhr, state, error) ->
        resp = JSON.parse xhr.responseText
        $.gritter.add 
          title: I18n.t('Error')
          text: "#{Object.keys(resp.errors)[0].charAt(0).toUpperCase() + Object.keys(resp.errors)[0].slice(1)} #{resp.errors[Object.keys(resp.errors)[0]]}"
    return false
  change_name: ->
    $.post("/u/#{@model.get('id')}/name", name: $("#changed_name").val(), null, 'json')
      .success (resp) =>
        @model.set resp
        $.gritter.add
          title: I18n.t('Success')
          text: I18n.t('name_change', {name: @model.escape('name')})
      .error (xhr, state, error) ->
        resp = JSON.parse xhr.responseText
        $.gritter.add 
          title: I18n.t('Error')
          text: "#{Object.keys(resp.errors)[0].charAt(0).toUpperCase() + Object.keys(resp.errors)[0].slice(1)} #{resp.errors[Object.keys(resp.errors)[0]]}"
    return false
    
  render: ->
    @$el.html(@template(model: @model))

    setTimeout (=>
      @on_tagline_change()
      ), 150
    this

class @PictureEditOverlayView extends Backbone.View
  model: User
  fileuploader_loaded: false
  template: _.template("
    <h3>#{I18n.t('picture_overlay.h3')}</h3>
    <p>
      #{I18n.t('picture_overlay.p')}
    </p>
    <ul class='accordion'>
      <li id='profilepic_accordion' class=''>
        <div class='title'>
          <h5>#{I18n.t('picture_overlay.profile.h5')}</h5>
          <p>#{I18n.t('picture_overlay.profile.p')}</p>
        </div>
        <div class='content'>
          <form action='https://credport-profilepictures.s3.amazonaws.com' method='post' enctype='multipart/form-data' id='uploader' data-direct-upload>
            <div class='dropzone'>
              
            </div>
            <input type='hidden' name='key' value=''>
            <input type='hidden' name='AWSAccessKeyId' value=''>
            <input type='hidden' name='acl' value='public-read'>
            <input type='hidden' name='policy' value=''>
            <input type='hidden' name='signature' value=''>
            <input type='hidden' name='success_action_status' value='201'>
            <p>
              #{I18n.t('choose_file')}<input type='file' name='file' value='' data-direct-upload=true>
            </p>
            <div class='nice round progress'><span class='meter'></span></div>

          </form>
          <div class='gallery'></div>
        </div>
      </li>
      <li id='backgroundpic_accordion' class=''>
        <div class='title'>
          <h5>#{I18n.t('picture_overlay.background.h5')}</h5>
          <p>#{I18n.t('picture_overlay.background.p')}</p>
        </div>
        <div class='content'>
          <form action='https://credport-backgroundpictures.s3.amazonaws.com' method='post' enctype='multipart/form-data' id='backgrounduploader' data-direct-upload>
            <div class='dropzone' style='background: url(<%= model.get('background_picture') %>) no-repeat center center;-webkit-background-size: cover;          -moz-background-size: cover;          -o-background-size: cover;          background-size: cover;'>
            </div>
            <input type='hidden' name='key' value=''>
            <input type='hidden' name='AWSAccessKeyId' value=''>
            <input type='hidden' name='acl' value='public-read'>
            <input type='hidden' name='policy' value=''>
            <input type='hidden' name='signature' value=''>
            <input type='hidden' name='success_action_status' value='201'>
            <p>
              #{I18n.t('choose_file')}<input type='file' name='file' value='' data-direct-upload=true>
            </p>
            <div class='nice round progress'><span class='meter'></span></div>

          </form>
        </div>
      </li>
    </ul>
  ")
  events:
    'click .accordion > li > .title': 'clickAccordion'
  clickAccordion: (evt) ->
    if @$('#profilepic_accordion').has(evt.target).length > 0
      mixpanel.track "Profile:Edit:ProfilePic:Toggle"
      mixpanel.people.increment "Profile:Edit:ProfilePic:Toggle"
    else
      mixpanel.track "Profile:Edit:BackgroundPic:Toggle"
      mixpanel.people.increment "Profile:Edit:BackgroundPic:Toggle"
  prepareLoader: ->
    if @fileuploader_loaded
      @getLoader()
    else
      @on 'fileuploader_loaded', @getLoader, this
  getLoader: ->
    $form = @$ '#uploader'
    $backform = @$ '#backgrounduploader'
    that = this
    dropzone = $form.find('.dropzone')
    backdropzone = $backform.find '.dropzone'
    $(document).bind 'dragenter', (e) ->
      if dropzone.is e.target
        dropzone.addClass 'show'
      else if backdropzone.is e.target
        backdropzone.addClass 'show'
      else
        e.preventDefault()
    $(document).bind 'dragleave drop', (e) ->
      if dropzone.is e.target
        dropzone.removeClass 'show'
      else if backdropzone.is e.target
        backdropzone.removeClass 'show'
      else
        e.preventDefault()
    $form.fileupload
        url: $form.attr('action')
        type: 'POST'
        autoUpload: true
        dataType: 'xml'
        add: (event, data) ->
          if $.inArray(data.files[0].name.split('.').pop().toLowerCase(), ['gif','png','jpg','jpeg', 'svg']) == -1
            $.gritter.add 
              title: I18n.t("Error")
              text: I18n.t('Invalid File Extension')
          else
            $.ajax
              url: '/forms/profilepicture'
              type: 'POST'
              dataType: 'json'
              data: 
                filename: data.files[0].name
              async: false
              success: (data) ->
                $form.find('input[name=key]').val(data.key)
                $form.find('input[name=policy]').val(data.policy)
                $form.find('input[name=signature]').val(data.signature)
                $form.find('input[name=AWSAccessKeyId]').val(data.aws_key)
            $(this).fileupload('process', data).done ->
                data.submit();
        send: (e, data) ->
          $form.find('.progress').addClass 'show'
        progress: (e, data) ->
          percent = Math.round((e.loaded / e.total) * 100)
          $form.find('.progress .meter').css('width', percent + '%')
          return this
        fail: (e, data) ->
          $.gritter.add
            title: I18n.t("Error")
            text: I18n.t("Something went wrong")
        success: (data) ->
          current = that.model.get('profile_pictures')
          url = $(data).find('Location').text()
          that.addProfilePicture $(data).find('Location').text()
        done: (e, data) ->
          $form.find('.progress').removeClass 'show'
        dropZone: $form.find('.dropzone')
        process: [
          {
              action: 'load',
              fileTypes: /^image\/(gif|jpeg|png)$/,
              maxFileSize: 5000000
          },
          {
              action: 'resize',
              maxWidth: 1920,
              maxHeight: 1200,
              minWidth: 150,
              minHeight: 150
          },
          {
              action: 'save',
              fileTypes: /^image\/(gif|jpeg|png)$/
          }
        ]
    $backform.fileupload
        url: $backform.attr('action')
        type: 'POST'
        autoUpload: true
        dataType: 'xml'
        add: (event, data) ->
          if $.inArray(data.files[0].name.split('.').pop().toLowerCase(), ['gif','png','jpg','jpeg', 'svg']) == -1
            $.gritter.add 
              title: I18n.t("Error")
              text: I18n.t('Invalid File Extension')
          else
            $.gritter.add
              title: I18n.t("Progress")
              text: I18n.t("Changing Background Picture")
            $.ajax
              url: '/forms/backgroundpicture'
              type: 'POST'
              dataType: 'json'
              data: 
                filename: data.files[0].name
              async: false
              success: (data) ->
                $backform.find('input[name=key]').val(data.key)
                $backform.find('input[name=policy]').val(data.policy)
                $backform.find('input[name=signature]').val(data.signature)
                $backform.find('input[name=AWSAccessKeyId]').val(data.aws_key)
            $(this).fileupload('process', data).done ->
                data.submit();
        send: (e, data) ->
          $backform.find('.progress').addClass 'show'
        progress: (e, data) ->
          percent = Math.round((e.loaded / e.total) * 100)
          $backform.find('.progress .meter').css('width', percent + '%')
          return this
        fail: (e, data) ->
          $.gritter.add
            title: I18n.t("Error")
            text: I18n.t("Something went wrong")
        success: (data) ->
          url = $(data).find('Location').text()
          that.changeBackgroundPicture $(data).find('Location').text()
          
        dropZone: $backform.find('.dropzone')
        process: [
          {
              action: 'load',
              fileTypes: /^image\/(gif|jpeg|png)$/,
              maxFileSize: 5000000
          },
          {
              action: 'resize',
              maxWidth: 1920,
              maxHeight: 1200,
              minWidth: 150,
              minHeight: 150
          },
          {
              action: 'save',
              fileTypes: /^image\/(gif|jpeg|png)$/
          }
        ]
  initialize: ->
    @model.on 'change', @render, this
    $.getScript("https://s3.amazonaws.com/credport-assets/assets/jquery.fileupload.js")
      .success =>
        @fileuploader_loaded = true
        @trigger 'fileuploader_loaded'
      .error (a,b,c) =>
        $.gritter.add
          title: I18n.t('Error')
          text: I18n.t("Could not load FileUploader")
  render: ->
    if @$('.accordion li.active').length > 0
      index = @$('.accordion li.active').index()
    @$el.html @template model: @model
    if index?
      $(@$('.accordion li')[index]).addClass 'active'
    @prepareLoader()
    @renderGallery()
    this
  renderGallery: ->
    gallery = @$ '.gallery'
    gallery.html ""
    _.each @model.get('profile_pictures'), (value) =>
      el = $ "<div class='picture' style='background-image: url(#{value});'><span class='delete'><span></div>"
      gallery.append el
      el.on 'click', '.delete', image: value, (e) =>
        $.gritter.add 
          title: I18n.t('Delete')
          text: I18n.t("Deleting picture in progress")
        current = @model.get('profile_pictures')
        @removeProfilePicture e.data.image
  changeBackgroundPicture: (picture, callack = null) ->
    $.post("/u/#{@model.get('id')}/backgroundpicture", picture: picture, null, 'text')
      .success (resp) =>
        @$('#backgrounduploader').find('.progress').removeClass 'show'
        @model.set {background_picture: resp}, {silent: true}
        @$('#backgrounduploader .dropzone').css('background-image',"url(#{resp})")
        $('body').css('background-image',"url(#{resp})")
        $.gritter.add 
          title: I18n.t('Success')
          text: I18n.t("Background Picture changed")
        if callback?
          callback()
      .error (resp) =>
        $.gritter.add 
          title: I18n.t('Error')
          text: I18n.t("Something went wrong")
  addProfilePicture: (picture, callback = null) ->
    $.post("/u/#{@model.get('id')}/profilepictures", picture: picture, null, 'json')
      .success (resp) =>
        @model.set profile_pictures: resp
        $.gritter.add 
          title: I18n.t('Success')
          text: I18n.t("Profile Picture added")
        if callback?
          callback()
      .error (resp) =>
        $.gritter.add 
          title: I18n.t('Error')
          text: I18n.t("Something went wrong there")
  removeProfilePicture: (picture) ->
    $.post("/u/#{@model.get('id')}/remove_profile_picture", picture: picture, null, 'json')
      .success (resp) =>
        @model.set profile_pictures: resp
        $.gritter.add 
          title: I18n.t('Success')
          text: I18n.t("Profile Picture deleted")
        if callback?
          callback()
      .error (resp) =>
        $.gritter.add 
          title: I18n.t('Error')
          text: I18n.t("Something went wrong there")

class @EditOverlayView extends Backbone.View
  className: 'edit-overlay-view'
  model: User
  events:
    'click .tabs-content li': 'clickTab'
  clickTab: (evt) ->
    mixpanel.track "Profile:Edit:#{evt.target.text}Tab"
    mixpanel.people.increment "Profile:Edit:#{evt.target.text}Tab"
  template: _.template("
    <ul class='tabs-content'>
      <li class='active' id='networksTab'></li>
      <li id='verifyTab'></li>
      <li id='personalTab'></li>
      <li id='picturesTab'></li>
      <li id='recommendations_to_approveTab'></li>
    </ul>
  ")
  header: "
    <h2>#{I18n.t('overlay_views.edit.title')}</h2>
    <dl id='edit-overlay-view-header-tabs' class='tabs'>
      <dd class='active'><a href='#networks'>#{I18n.t('edit_overlay.tabs.networks')}</a></dd>
      <dd class=''><a href='#verify'>#{I18n.t('edit_overlay.tabs.verifications')}</a></dd>
      <dd><a href='#personal'>#{I18n.t('edit_overlay.tabs.personal')}</a></dd>
      <dd class=''><a href='#pictures'>#{I18n.t('edit_overlay.tabs.pictures')}</a></dd>
    </dl>
    "
  initialize: ->
    @on 'attached', @attached, this
  addEditOverlayView: (view, selector, model= null) ->
    if !model?
      model = @model
    view = new view model: model
    @$(selector).append view.render().el
  render: ->
    @$el.html(@template(@model.toJSON()))

    @addEditOverlayView NetworksEditOverlayView, '#networksTab'
    @addEditOverlayView VerificationEditOverlayView, '#verifyTab'
    @addEditOverlayView PersonalEditOverlayView, '#personalTab'
    @addEditOverlayView PictureEditOverlayView, '#picturesTab'

    this
  attached: ->
    @$el.parent().parent().foundationTabs()
    @$el.foundationAccordion()
    @$el.parent().parent().click '#edit-overlay-view-header-tabs dd', @clickTab
