attribute :id, :classyear, :station, :visible, :classyear_string, :key, :value, :majors
node :majors do |a|
  escape_objects a.majors
end
child :school_scoped => :school do
  extends 'users/entity'
end
node :added_by do |a|
  partial 'users/entity_limited', :object => a.added_by.entity
end