attribute :id, :title, :from, :to, :key, :value, :visible, :date_string, :summary
node :from do |a|
  escape_objects a.from
end
node :to do |a|
  escape_objects a.from
end
child :workplace_scoped => :workplace do
  extends 'users/entity'
end
node :added_by do |a|
  partial 'users/entity_limited', :object => a.added_by.entity
end