application 'simple_rollback' do
  path '/dir1'
  repository 'repo'
  deploy_action :rollback
end

application 'simple_force_deploy' do
  path '/dir2'
  repository 'repo'
  deploy_action :force_deploy
end
