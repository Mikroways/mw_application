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

  describe file('/opt/redmine_app1') do
    it { should be_directory }
    it { should be_mode 750 }
    it { should be_owned_by 'redmine_app1' }
    it { should be_grouped_into 'root' }
  end

  describe port(5001) do
    it { should be_listening }
  end
end
