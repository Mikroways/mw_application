app = redmine 'redmine_app' do
  path '/opt/redmine_app'
  ruby '2.2.4'
  variables 'database' => {
    'production' => {
      'adapter'   => 'sqlite3',
      'database'  => 'db/production.sqlite3',
      'pool'      => 5,
      'timeout'   => 5000
    }
  }
  migrate true
end

rbenv_script 'run redmine' do
  user lazy { app.user }
  cwd lazy { app.current_path }
  rbenv_version lazy { app.ruby }
  environment lazy { app.environment }
  code %(pkill -9 -u `id -u` ruby || bundle exec unicorn -p 5000 -D > /tmp/redmine.log 2>&1)
  action :nothing
  subscribes :run, 'redmine[redmine_app]'
end

app1 = redmine 'redmine_app1' do
  path '/opt/redmine_app1'
  ruby '2.2.4'
  variables 'database' => {
    'production' => {
      'adapter'   => 'sqlite3',
      'database'  => 'db/production.sqlite3',
      'pool'      => 5,
      'timeout'   => 5000
    }
  }
  migrate true
end

rbenv_script 'run redmine1' do
  user lazy { app1.user }
  cwd lazy { app1.current_path }
  rbenv_version lazy { app1.ruby }
  environment lazy { app1.environment }
  code %(pkill -9 -u `id -u` ruby || bundle exec unicorn -p 5001 -D > /tmp/redmine1.log 2>&1)
  action :nothing
  subscribes :run, 'redmine[redmine_app1]'
end
