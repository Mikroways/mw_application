

app = application_ruby 'samson' do
  repository 'https://github.com/zendesk/samson.git'
  path '/opt/applications/samson'
  ruby '2.2.4'
  variables({
    'database' => {
      'production' => {
        'adapter' => 'sqlite3',
        'database' => 'db/db.sqlite3',
        'pool' => 5,
        'timeout' => 5000
      }
    }
  })

  before_migrate do
    package new_resource.value_for_platform_family(
      debian: %w(libpq-dev libmysqlclient-dev nodejs),
      rhel: %w(postgresql-devel mysql-libs nodejs)
    )

    rbenv_script 'rbenv local' do
      cwd release_path
      rbenv_version application_resource.ruby
      code %{rbenv local #{application_resource.ruby}}
    end
    file "#{shared_path}/config/database.yml" do
      owner application_resource.owner
      mode '0640'
      content application_resource.variables['database'].to_yaml
    end
    rbenv_script 'bundle install' do
      cwd release_path
      code %{bundle install --frozen --without development test}
    end
  end
end

execute 'bootstrap' do
  environment app.application_rails_environment
  user app.owner
  cwd app.current_path
  command './script/bootstrap'
  action :nothing
  subscribes :run, 'application_ruby[samson]', :immediately
end

application_service 'samson' do
  path '/opt/applications/samson/current'
  environment application_rails_environment
  command './bin/bundle exec puma 2>> /tmp/samson.err.log >> /tmp/samson.log'
  user 'samson'
end
