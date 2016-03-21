application 'simple_app' do
  path '/dir'
  repository 'repo'
  revision 'rev'
  shared_directories %w(dir1 dir2)
  environment 'VAR' => 'VALUE'
  group 'group'
  before_deploy do
    directory 'test_before_deploy'
  end
  migration_command 'migration command'
end
