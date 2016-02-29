define_application_ruby 'redmine' do
  shared_directories %w(log tmp files plugins public/themes/custom)
  repository 'https://github.com/redmine/redmine.git'
  revision '3.1-stable'
  environment application_rails_environment
  migration_command <<-MIGRATE
    bundle exec rake db:migrate &&
    bundle exec rake redmine:plugins:migrate &&
    bundle exec rake generate_secret_token &&
    REDMINE_LANG=en bundle exec rake redmine:load_default_data
  MIGRATE

  helpers do
    def database_content
      variables['database'].to_yaml
    end
  end

  before_migrate do
    package new_resource
      .value_for_platform_family(debian: 'libmagickwand-dev',
                                 rhel: 'ImageMagick-devel')
    package new_resource
      .value_for_platform_family(debian: 'libsqlite3-dev',
                                 rhel: 'sqlite-devel')

    rbenv_script 'rbenv local' do
      cwd release_path
      rbenv_version application_resource.ruby
      code %(rbenv local #{application_resource.ruby})
    end

    # Must be run only id exists a Gemfile.lock file
    rbenv_script 'bundle update' do
      cwd release_path
      rbenv_version application_resource.ruby
      code %(bundle update)
      action :nothing
      only_if "test -f #{release_path}/Gemfile.lock"
    end

    file "#{release_path}/Gemfile.local" do
      owner application_resource.user
      content 'gem "unicorn", "~> 5.0.0"'
      notifies :run, 'rbenv_script[bundle update]'
    end

    # Needed to run bundle, after this action, it will be replaced by a
    # sym link
    file "#{release_path}/config/database.yml" do
      owner application_resource.user
      mode '0640'
      content application_resource.database_content
      sensitive true
      notifies :run, 'rbenv_script[bundle update]'
    end

    # This is the definitive file
    file "#{shared_path}/config/database.yml" do
      owner application_resource.user
      mode '0640'
      content application_resource.database_content
      notifies :run, 'rbenv_script[bundle update]'
    end

    # Only for the very first time. This means when there is
    # no Gemfile.lock created
    rbenv_script 'bundle install' do
      cwd release_path
      rbenv_version application_resource.ruby
      code %(bundle install --without development test)
      not_if "test -f #{release_path}/Gemfile.lock"
    end
  end
end
