require 'spec_helper'

describe 'application_ruby_test::default' do
  before do
    stub_command('git --version >/dev/null').and_return(true)
  end

  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      platform: 'ubuntu', # needed for ruby_rbenv
      version: '14.04', # needed for ruby_rbenv
      step_into: 'application_ruby')
    runner.converge(described_recipe)
  end

  context 'compiling the test recipe' do
    it 'converges successfully' do
      expect(chef_run).to deploy_application_ruby('simple_ruby_app')
      expect(chef_run).to create_user('simple_ruby_app')
      expect(chef_run).to deploy_deploy('simple_ruby_app')
    end
  end

  context 'stepping into application[simple_ruby_app] resource' do
    it 'saves all node attributes' do
      attributes = chef_run.node['applications']['application_ruby']['simple_ruby_app']
      expect(attributes).not_to be_empty
      expect(attributes.keys.sort)
        .to eq %w(user group path shared_directories source repository migration_command migrate environment
                  revision symlink_before_migrate deploy_action socket ruby)
        .sort
      expect(attributes['ruby']).to eq '2.2.4'
    end

    it 'installs rbenv' do
      expect(chef_run).to include_recipe('ruby_rbenv::system_install')
      expect(chef_run).to include_recipe('ruby_build')
    end

    it 'installs ruby 2.2.4' do
      expect(chef_run).to install_rbenv_ruby('2.2.4')
    end

    it 'install bundler gem' do
      expect(chef_run).to install_rbenv_gem('bundler')
        .with(rbenv_version: '2.2.4')
    end
  end
end
