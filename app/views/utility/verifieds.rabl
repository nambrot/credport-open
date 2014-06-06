object false

node :emails do
  @emails.map do |email|
    partial("users/email", :object => email)
  end
end

node :phones do
  @phones.map do |phone|
    partial("users/phone", :object => phone)
  end
end

node :websites do
  @websites.map do |website|
    partial("users/website", :object => website)
  end
end