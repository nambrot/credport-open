object false
node :title do
  'Work Experience'
end

node :type do
  'extended-object-list'
end

child @user.work_attributes => :data do
  extends 'users/work_attribute'
end

node :user do
  api_v1_user_url(@user, :protocol => 'https')
end