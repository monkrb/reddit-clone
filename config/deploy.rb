# after "deploy:update_code", "deploy:set_permissions"
after "deploy:update_code", "deploy:symlink_configs"
after "deploy:update_code", "deploy:sass"

namespace :deploy do
  desc "Start the app"
  task :start, :roles => :app do
    sudo "a2ensite #{vhost}"
    sudo "/etc/init.d/apache2 reload"
  end

  desc "Stop the app"
  task :stop, :roles => :app do
    sudo "a2dissite #{vhost}"
    sudo "/etc/init.d/apache2 reload"
  end

  desc "Restart the app"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :set_permissions, :roles => :app do
    run "chmod -R o+w #{release_path}/public"
  end

  desc "Symlink config files"
  task :symlink_configs, :roles => :app, :except => { :no_symlink => true } do
    %w(settings).each do |filename|
      run "ln -nfs #{shared_path}/config/#{filename}.yml #{release_path}/config/#{filename}.yml"
    end
  end

  desc "Generate static CSS"
  task :sass, :roles => :app do
    run "cd #{release_path} && env RACK_ENV=#{fetch :rack_env} ./vendor/thor/bin/thor monk:sass"
  end
end
