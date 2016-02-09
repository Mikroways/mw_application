require 'spec_helper'

describe 'integration_test::default' do
  describe user('redmine_app') do
    it { should exist }
    it { should have_login_shell '/bin/bash' }
  end

  describe file('/opt/redmine_app') do
    it { should be_directory }
    it { should be_mode 750 }
    it { should be_owned_by 'redmine_app' }
    it { should be_grouped_into 'root' }
  end

  describe port(5000) do
    it { should be_listening }
  end

  describe command('curl "http://localhost:5000/login"') do
    its(:stdout) { should match(/form action="\/login"/) }
  end

end
