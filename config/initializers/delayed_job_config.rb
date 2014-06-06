# config/initializers/delayed_job_config.rb
Delayed::Worker.max_attempts = 1
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.read_ahead = 10


Rails.application.config.dj_mon.username = "username"
Rails.application.config.dj_mon.password = "password"
