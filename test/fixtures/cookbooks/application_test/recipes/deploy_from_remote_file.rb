application 'remote_source' do
  path '/dir'
  source 'http://example.com/download/file.tgz'
  shared_directories %w(dir1 dir2)
  group 'group'
  before_deploy do
    directory 'test_before_deploy'
  end
end
