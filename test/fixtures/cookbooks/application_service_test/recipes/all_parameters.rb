application_service 'all_params' do
  path '/tmp'
  command 'a command'
  user 'some_user'
  environment :home => '/home/some_user', :path => '/usr/bin'
  start_on 'started networking'
  stop_on 'stopped networking'
  respawn true
  respawn_limit "2 10"
  pre_start "pre start command"
  post_start "post start command"
  pre_stop "pre stop command"
  post_stop "post stop command"
end

application_service 'no_respawn' do
  path '/tmp'
  command 'a command'
  respawn false
end
