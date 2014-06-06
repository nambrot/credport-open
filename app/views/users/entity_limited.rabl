cache
attribute :name, :url, :image

node :context do |a|
  escape_objects({
      :name => a.context.name,
      :title => a.context.title
    })
  end