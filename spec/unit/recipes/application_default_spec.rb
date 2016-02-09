#
# Cookbook Name:: mw_application
# Spec:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'application_test::default' do

  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(step_into: 'application')
    runner.converge(described_recipe)
  end

  context 'compiling the test recipe' do

    it 'converges successfully' do
      expect(chef_run).to deploy_application('simple_app')
    end
  end

  context 'stepping into application[simple_app] resource' do

    it 'saves all node attributes' do
      attributes = chef_run.node['applications']['application']['simple_app']
      expect(attributes).not_to be_empty
      expect(attributes.keys.sort)
        .to eq %w(user group path shared_directories repository migration_command migrate environment
        revision symlink_before_migrate deploy_action socket)
        .sort
      expect(attributes['deploy_action']).to eq :deploy
      expect(attributes['environment']).to eq 'VAR' => 'VALUE'
      expect(attributes['group']).to eq 'group'
      expect(attributes['migrate']).to eq false
      expect(attributes['migration_command']).to eq 'migration command'
      expect(attributes['path']).to eq '/dir'
      expect(attributes['repository']).to eq 'repo'
      expect(attributes['revision']).to eq 'rev'
      expect(attributes['shared_directories']).to eq ['dir1', 'dir2']
      expect(attributes['socket']).to eq '/dir/shared/var/socket'
      expect(attributes['symlink_before_migrate']).to eq %w(config/database.yml)
      expect(attributes['user']).to eq 'simple_app'
    end

    it 'creates default user' do
      expect(chef_run).to create_user('simple_app')
      .with(supports: { :manage_home => true },
          manage_home: true,
          home: '/home/simple_app',
          shell: '/bin/bash')

    end

    it 'creates base directory with permissions' do
      expect(chef_run).to create_directory('/dir')
      .with(
        recursive: true,
        owner: 'simple_app',
        group: 'group')
    end

    it 'creates shared directory' do
      expect(chef_run).to create_directory('/dir/shared')
      .with(
        recursive: true,
        user: 'simple_app')
    end

    # As symlink_before_migrate includes config/database.yml by default it must
    # create  shared/config
    it 'creates shared/config' do
      expect(chef_run).to create_directory('/dir/shared/config')
      .with(
        recursive: true,
        user: 'simple_app'
      )
    end

    it 'creates shared/var because of socket unix' do
      expect(chef_run).to create_directory('/dir/shared/var')
      .with(
        recursive: true,
        user: 'simple_app',
      )
    end

    it 'creates shared directories' do
      %w(dir1 dir2).each do |dir|
        expect(chef_run).to create_directory("/dir/shared/#{dir}")
        .with(
          recursive: true,
          user: 'simple_app',
        )
      end
    end

    context 'deploy resource' do
      it 'deploys application' do
        expect(chef_run).to deploy_deploy('simple_app')
        .with(
            repository: 'repo',
            revision: 'rev',
            deploy_to: '/dir',
            purge_before_symlink: %w(dir1 dir2),
            symlinks: {'dir1' => 'dir1', 'dir2' => 'dir2'},
            symlink_before_migrate: { 'config/database.yml' => 'config/database.yml'},
            migrate: false,
            migration_command: 'migration command',
            environment: { 'VAR' => 'VALUE'},
            user: 'simple_app')
          end
      end

  end

end
