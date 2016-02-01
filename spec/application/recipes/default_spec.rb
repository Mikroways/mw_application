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
      expect(chef_run).to install_application('simple_app')
    end
  end

  context 'stepping into application[simple_app] resource' do

    it 'saves all node attributes' do
      attributes = chef_run.node['applications']['application']['simple_app']
      expect(attributes).not_to be_empty
      expect(attributes.keys.sort)
        .to eq %w(owner path shared_directories repository revision symlink_before_migrate deploy_action socket)
        .sort
      expect(attributes['owner']).to eq 'simple_app'
      expect(attributes['path']).to eq '/dir'
      expect(attributes['shared_directories']).to be_empty
      expect(attributes['repository']).to eq 'repo'
      expect(attributes['revision']).to be_nil
      expect(attributes['symlink_before_migrate']).to eq %w(config/database.yml)
      expect(attributes['deploy_action']).to eq :deploy
      expect(attributes['socket']).to eq '/dir/shared/var/socket'
    end

    it 'creates default user' do
      expect(chef_run).to create_user('simple_app')
      .with(supports: { :manage_home => true },
          manage_home: true,
          home: '/home/simple_app',
          shell: '/bin/bash')

    end

    # As symlink_before_migrate includes config/database.yml by default it must
    # create  shared/config
    it 'creates shared/config' do
      expect(chef_run).to create_directory('/dir/shared/config')
      .with(recursive: true)
    end

    it 'creates shared/var' do
      expect(chef_run).to create_directory('/dir/shared/var')
      .with(recursive: true)
    end
  end

  context 'stepping into application[shared_dirs] resource' do

    it 'creates shared directories' do
      skip
    end
  end
end
