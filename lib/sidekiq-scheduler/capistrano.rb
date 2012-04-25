Capistrano::Configuration.instance.load do
  before "deploy",        "sidekiq_scheduler:quiet"
  after "deploy:stop",    "sidekiq_scheduler:stop"
  after "deploy:start",   "sidekiq_scheduler:start"
  after "deploy:restart", "sidekiq_scheduler:restart"

  _cset(:sidekiq_timeout) { 10 }
  _cset(:sidekiq_role) { :app }

  namespace :sidekiq_scheduler do

    desc "Quiet sidekiq-scheduler with sidekiq (stop accepting new work)"
    task :quiet, :roles => lambda { fetch(:sidekiq_role) } do
      run "cd #{current_path} && if [ -f #{current_path}/tmp/pids/sidekiq.pid ]; then #{fetch(:bundle_cmd, "bundle")} exec sidekiqctl quiet #{current_path}/tmp/pids/sidekiq.pid ; fi"
    end

    desc "Stop sidekiq-scheduler with sidekiq"
    task :stop, :roles => lambda { fetch(:sidekiq_role) } do
      run "cd #{current_path} && if [ -f #{current_path}/tmp/pids/sidekiq.pid ]; then #{fetch(:bundle_cmd, "bundle")} exec sidekiqctl stop #{current_path}/tmp/pids/sidekiq.pid #{fetch :sidekiq_timeout} ; fi"
    end

    desc "Start sidekiq-scheduler with sidekiq"
    task :start, :roles => lambda { fetch(:sidekiq_role) } do
      rails_env = fetch(:rails_env, "production")
      run "cd #{current_path} ; nohup #{fetch(:bundle_cmd, "bundle")} exec sidekiq-scheduler -e #{rails_env} -C #{current_path}/config/sidekiq.yml -P #{current_path}/tmp/pids/sidekiq.pid >> #{current_path}/log/sidekiq.log 2>&1 &", :pty => false
    end

    desc "Restart sidekiq-scheduler with sidekiq"
    task :restart, :roles => lambda { fetch(:sidekiq_role) } do
      stop
      start
    end

  end
end