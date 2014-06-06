cache
attribute :name, :title
node :application do |context|
  partial 'users/entity_limited', :object => context.application.entity
end