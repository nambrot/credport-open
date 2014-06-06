namespace :matrix do
  task :reboot  do
    system('rake db:drop')
    system('rake db:create')
    system('rake db:migrate')
    system('rake db:seed')
    system('rake neo4j:reset_yes_i_am_sure')
  end
end
