object false
node :title do
  'Verfications'
end

node :type do
  'verfication-list'
end

node :data do |a|
  {
    :identities => @user.identities.map{ |identity| {
      :image => identity.context.application.entity.image,
      :title => identity.context.name.capitalize + " Connected",
      :subtitle => identity.subtitle,
      :properties => identity.properties,
    } },
    :real => @user.emails.map { |email| partial('users/email_verification', :object => email) }
    .concat( @user.phones.map { |phone| partial('users/phone_verification', :object => phone) })
  }
end

node :user do
  api_v1_user_url(@user, :protocol => 'https')
end