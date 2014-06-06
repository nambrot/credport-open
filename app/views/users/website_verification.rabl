node do |a|
  escape_objects({
        :image => asset_path("browser.png"),
        :subtitle => a.title,
        :title => t("Webpage Verified"),
        :properties => {
          :url => a.url
        }
      })
end