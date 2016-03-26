#
# Cookbook Name:: mw_application
# Spec:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'application_dsl_test::default' do
  before do
    stub_command('git --version >/dev/null').and_return(true)
  end

  let(:chef_run_my_app) do
    runner = ChefSpec::SoloRunner.new(
      step_into: 'my_app',
      platform: 'ubuntu', # needed for ruby_rbenv
      version: '14.04' # needed for ruby_rbenv
    )
    runner.converge(described_recipe)
  end

  let(:chef_run_my_ruby_app) do
    runner = ChefSpec::SoloRunner.new(
      step_into: 'my_ruby_app',
      platform: 'ubuntu', # needed for ruby_rbenv
      version: '14.04' # needed for ruby_rbenv
    )
    runner.converge(described_recipe)
  end

  context 'stepping into my_app[app_name_dsl] resource' do
    it 'saves all node attributes' do
      attributes = chef_run_my_app.node['applications']['my_app']['app_name_dsl']
      expect(attributes).not_to be_empty
    end

    it 'creates user' do
      expect(chef_run_my_app).to create_user('app_name_dsl')
    end

    it 'creates needed directories' do
      %w( /opt/app_name_dsl
          /opt/app_name_dsl/shared
          /opt/app_name_dsl/shared/a
          /opt/app_name_dsl/shared/b
          /opt/app_name_dsl/shared/c/d
          /opt/app_name_dsl/shared/var).each do |dir|
        expect(chef_run_my_app).to create_directory(dir)
      end
    end

    it 'deploys application' do
      expect(chef_run_my_app).to deploy_deploy('app_name_dsl')
    end

    it 'set default values defined by dsl' do
      expect(chef_run_my_app).to deploy_my_app('app_name_dsl').with(
        shared_directories: %w(a b c/d),
        repository: 'some_repo',
        revision: 'some_rev',
        path: '/opt/app_name_dsl'
      )
    end
  end

  context 'stepping into my_ruby_app[ruby_app_name_dsl] resource' do
    it 'saves all node attributes' do
      attributes = chef_run_my_ruby_app.node['applications']['my_ruby_app']['ruby_app_name_dsl']
      expect(attributes).not_to be_empty
    end

    it 'creates user' do
      expect(chef_run_my_ruby_app).to create_user('ruby_app_name_dsl')
    end

    it 'creates needed directories' do
      %w( /opt/ruby_app_name_dsl
          /opt/ruby_app_name_dsl/shared
          /opt/ruby_app_name_dsl/shared/e
          /opt/ruby_app_name_dsl/shared/f
          /opt/ruby_app_name_dsl/shared/g/h
          /opt/ruby_app_name_dsl/shared/var).each do |dir|
        expect(chef_run_my_ruby_app).to create_directory(dir)
      end
    end

    it 'creates database file before deploying' do
      expect(chef_run_my_ruby_app).to create_file '/opt/ruby_app_name_dsl/shared/database_new.yml'
    end
    it 'deploys application' do
      expect(chef_run_my_ruby_app).to deploy_deploy('ruby_app_name_dsl')
    end

    it 'set default values defined by dsl' do
      expect(chef_run_my_ruby_app).to deploy_my_ruby_app('ruby_app_name_dsl').with(
        shared_directories: %w(e f g/h),
        repository: 'other_repo',
        revision: 'other_rev',
        sample: 'sample_value',
        path: '/opt/ruby_app_name_dsl'
      )
    end
  end
end
