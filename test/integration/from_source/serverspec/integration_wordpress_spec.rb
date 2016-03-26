require 'spec_helper'

describe 'integration_test::from_source' do
  let(:release) { '65d89263dad6154fdc8b747e9ef4e357' }
  describe user('wp_main') do
    it { should exist }
    it { should have_login_shell '/bin/bash' }
  end

  describe file('/opt/wordpress') do
    it { should be_directory }
    it { should be_mode 750 }
    it { should be_owned_by 'wp_main' }
    it { should be_grouped_into 'root' }
  end

  describe file('/opt/wordpress/releases') do
    it { should be_directory }
    it { should be_owned_by 'wp_main' }
    it { should be_grouped_into 'root' }
  end

  %w(wp-content/languages wp-content/plugins wp-content/themes wp-content/uploads).each do |dir|
    describe file("/opt/wordpress/current/#{dir}") do
      it { should be_symlink }
      it { should be_linked_to "/opt/wordpress/shared/#{dir}" }
      it { should be_owned_by 'wp_main' }
      it { should be_grouped_into 'root' }
    end
  end

  describe file('/opt/wordpress/current/wp-config.php') do
    it { should be_symlink }
    it { should be_linked_to '/opt/wordpress/shared/wp-config.php' }
    it { should be_owned_by 'wp_main' }
    it { should be_grouped_into 'root' }
  end

  describe command('md5sum /opt/wordpress/releases/wordpress-4.4.2.tar.gz | grep --only-matching -m 1 \'^[0-9a-f]*\' | tr -d \'\n\'') do
    its(:stdout) { should eq release }
  end

  describe file('/opt/wordpress/current') do
    it { should be_symlink }
    it { should be_linked_to "/opt/wordpress/releases/#{release}" }
    it { should be_owned_by 'wp_main' }
    it { should be_grouped_into 'root' }
  end
end
