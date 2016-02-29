define_application 'my_app' do
  shared_directories %w(a b c/d)
  repository 'some_repo'
  revision 'some_rev'
  symlink_before_migrate %w(database.yml)
  before_migrate do
    file "#{application_resource.shared_path}/database.yml"
  end
end

define_application_ruby 'my_ruby_app' do
  shared_directories %w(e f g/h)
  repository 'other_repo'
  revision 'other_rev'
  ruby '2.2.4'
  symlink_before_migrate %w(database_new.yml)
  before_migrate do
    file "#{application_resource.shared_path}/#{application_resource.database.name}"
  end

  helpers do
    def database_name
      'database_new.yml'
    end
  end
end
