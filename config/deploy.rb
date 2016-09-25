require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'
require 'yaml'

FLASH = YAML.load(File.read(File.expand_path('../../.env/production_env.yml', __FILE__)))

set :deploy_to,     FLASH['app_root']
set :user,          FLASH['server_user']
set :port,          FLASH['server_ssh_port']
set :repository,    FLASH['app_repo']
set :rails_env,     FLASH['rails_env']
set :forward_agent, true

task :production do
  set :domain,        FLASH['server_domain']
  set :branch,        FLASH['app_repo_branch']
  set :rails_env,     'production'
  set :shared_paths,  ['config/database.yml', 'config/secrets.yml', 'log', 'tmp', '.env/production_env.yml']
end

task :environment do
  queue 'export PATH=/usr/local/rbenv/bin:/usr/local/rbenv/shims:$PATH'
  queue 'source ~/.session_vars'
end

task setup: :environment do
  queue "mkdir -m 750 -p #{deploy_to}/#{shared_path}/log"
  queue "mkdir -m 750 -p #{deploy_to}/#{shared_path}/config"
  queue "mkdir -m 750 -p #{deploy_to}/#{shared_path}/tmp/log"
  queue "mkdir -m 750 -p #{deploy_to}/#{shared_path}/tmp/pids"
  queue "mkdir -m 750 -p #{deploy_to}/#{shared_path}/tmp/sockets"
end

task deploy: :environment do
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'
    to :launch do
      invoke :'server:restart'
    end
  end
end

namespace :server do
  task start: :environment do
    queue "cd $APP_ROOT/current && rails_env=#{rails_env} && bin/puma.sh start"
  end

  task stop: :environment do
    queue "cd $APP_ROOT/current && rails_env=#{rails_env} && bin/puma.sh stop"
  end

  task restart: :environment do
    queue "cd $APP_ROOT/current && rails_env=#{rails_env} && bin/puma.sh restart"
  end
end
