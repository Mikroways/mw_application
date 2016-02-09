application 'simple_rollback' do
  path '/dir1'
  repository 'repo'
  action :rollback
end

application 'simple_force_deploy' do
  path '/dir2'
  repository 'repo'
  action :force_deploy
end

application 'simple_delete' do
  path '/dir3'
  repository 'repo'
  action :delete
end
