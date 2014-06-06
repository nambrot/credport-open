node :title do
  'Education Experience'
end

node :type do
  'extended-object-list'
end

child @user.education_attributes => :data do
  extends 'users/education_attribute'
  end


node :user do
  api_v1_user_url(@user, :protocol => 'https')
end