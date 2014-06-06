object false
cache [@user, params[:include], params[:callback], I18n.locale]
child @user do

  attributes :to_param => :id
  attributes :name, :tagline
  node :image do |a|
    escape_objects((a.image ? a.image : asset_path('user.png')))
  end
  node :url do |a|
    user_url(a, :protocol => 'http')
  end
  node :profile_pictures do |a|
    escape_objects(a.profile_pictures.count > 0 ? a.profile_pictures.map(&:url) : [asset_path('user.png')])
  end
  node :background_picture do |a|
    escape_objects(a.background_picture ? a.background_picture : asset_path('car.jpg'))
  end
  child({:education_attributes => :education}, { :if => lambda {|m| include_education? } } ) do
    extends 'users/education_attribute'
  end

  child({:work_attributes => :work}, { :if => lambda {|m| include_work? }}) do
    extends 'users/work_attribute'
  end

  node :verifications, :if => lambda {|m| include_verifications?} do |a|
    escape_objects({
          :identities => @user.third_identities.map{ |identity| {
            :image => identity.context.application.entity.image,
            :title => t(identity.context.title) + " " + t("api.verification.network.connected"),
            :subtitle => identity.subtitle || "",
            :properties => identity.properties.merge({:url => identity.url}),
          } },
          :real => @user.emails.map { |email| partial('users/email_verification', :object => email) }
          .concat( @user.phones.map { |phone| partial('users/phone_verification', :object => phone) })
          .concat( @user.websites.map { |website| partial('users/website_verification', :object => website)})      
        })
  end

  node :stats, :if => lambda{|m| include_stats? } do |a|
    getStats
  end

  child({:reviews => :reviews}, {:if => lambda{|m| include_reviews? }}) do
    extends 'users/review'
  end

  node :links do
    {
      :work => api_v1_user_work_url(@user, :protocol => 'https'),
      :education => api_v1_user_education_url(@user, :protocol => 'https'),
      :verifications => api_v1_user_verifications_url(@user, :protocol => 'https'),
      :reviews => api_v1_user_reviews_url(@user, :protocol => 'https'),
      :identities => api_v1_user_identities_url(@user, :protocol => 'https'),
      :commonconnections => api_v1_user_commonconnections_url(@user, :protocol => 'https'),
      :commoninterests => api_v1_user_commoninterests_url(@user, :protocol => 'https'),
      :stats => api_v1_user_stats_url(@user, :protocol => 'https'),
    }
  end
end

node do |a|
  {
    :status => @status || 200,
    :error => @error || '',
    :loggedin => @loggedin || false
  }
end

