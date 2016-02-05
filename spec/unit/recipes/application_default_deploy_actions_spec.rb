#
# Cookbook Name:: mw_application
# Spec:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'application_test::deploy_actions' do

  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(step_into: 'application')
    runner.converge(described_recipe)
  end

  context 'compiling the test recipe' do

    it 'converges successfully' do
      expect(chef_run).to install_application('simple_rollback')
      expect(chef_run).to install_application('simple_force_deploy')
    end

  end

  context 'stepping into application[simple_rollback] resource' do

    it 'creates user' do
      expect(chef_run).to create_user('simple_rollback')
    end
    it 'creates needed directories' do
      %w(/dir1 /dir1/shared /dir1/shared/config /dir1/shared/var).each do |dir|
        expect(chef_run).to create_directory(dir)
      end
    end
    it 'deploys application' do
      expect(chef_run).to rollback_deploy('simple_rollback')
    end
  end

  context 'stepping into application[simple_force_deploy] resource' do

    it 'creates user' do
      expect(chef_run).to create_user('simple_force_deploy')
    end
    it 'creates needed directories' do
      %w(/dir2 /dir2/shared /dir2/shared/config /dir2/shared/var).each do |dir|
        expect(chef_run).to create_directory(dir)
      end
    end

    it 'deploys application' do
      expect(chef_run).to force_deploy_deploy('simple_force_deploy')
    end
  end
end
