xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Credport Blog"
    xml.description "Credport's Blog with thoughts on Collaborative Consumption and Startups in general"
    xml.link posts_url

    for post in @posts
      xml.item do
        xml.title post.title
        xml.description truncate(strip_tags(post.body).gsub(/\s+/, ' '))
        xml.pubDate post.created_at.to_s(:rfc822)
        xml.link post_url(post)
        xml.guid post_url(post)
      end
    end
  end
end