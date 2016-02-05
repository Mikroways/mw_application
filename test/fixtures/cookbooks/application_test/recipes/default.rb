application 'simple_app' do
  path '/dir'
  repository 'repo'
  revision 'rev'
  shared_directories %w(dir1 dir2)
  environment 'VAR' => 'VALUE'
  group 'group'
  migration_command 'migration command'
end
