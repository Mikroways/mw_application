#
# Cookbook Name:: mw_application
# Spec:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'application_test::deploy_actions' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(step_into: 'application') do |node|
      node.set['applications']['application']['simple_rollback'] = 'some value'
      node.set['applications']['application']['simple_delete'] = 'some value'
    end
    runner.converge(described_recipe)
  end

  let(:chef_run_rollback_ok) do
    runner = ChefSpec::SoloRunner.new(step_into: 'application') do |node|
      node.set['applications']['application']['simple_rollback'] = 'some value'
    end
    runner.converge(described_recipe)
  end

  let(:chef_run_delete_ok) do
    runner = ChefSpec::SoloRunner.new(step_into: 'application') do |node|
      node.set['applications']['application']['simple_delete'] = 'some value'
    end
    runner.converge(described_recipe)
  end

  context 'compiling the test recipe with errors' do
    it 'raise exception if rollback not deployed application' do
      expect { chef_run_delete_ok }.to raise_error(RuntimeError)
    end

    it 'raise exception if delete not deployed application' do
      expect { chef_run_rollback_ok }.to raise_error(RuntimeError)
    end
  end

  context 'compiling the test recipe' do
    it 'converges successfully' do
      expect(chef_run).to rollback_application('simple_rollback')
      expect(chef_run).to force_deploy_application('simple_force_deploy')
      expect(chef_run).to delete_application('simple_delete')
    end

    # simple_delete attribte shall be deleted so we wont ask
    it 'sets node attributes' do
      expect(chef_run.node['applications']['application'].keys.sort).to eq %w(simple_force_deploy simple_rollback)
    end
  end

  context 'stepping into application[simple_rollback] resource' do
    it 'deploys application with rollback' do
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

  context 'stepping into application[simple_delete] resource' do
    it 'deploys application with rollback' do
      attributes = chef_run.node['applications']['application']['simple_delete']
      expect(attributes).to be_nil
    end
  end
end
