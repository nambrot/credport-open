node do |a|
  {
      :image => asset_path("email.png"),
      :subtitle => a.email.split('@')[0].gsub(/./, '*') + "@" + a.email.split('@')[1],
      :title => t("Email Address Verified"),
      :properties => {}
    }
end