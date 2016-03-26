#
# Cookbook Name:: mw_application
# Spec:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'application_test::deploy_from_remote_file' do
  before do
    md5sum = double
    allow_any_instance_of(Chef::Provider).to receive(:shell_out!)
      .with("curl -s 'http://example.com/download/file.tgz' | md5sum | grep --only-matching -m 1 '^[0-9a-f]*'")
      .and_return(md5sum)
    allow(md5sum).to receive(:stdout).and_return('1' * 32)

    stub_command("test \"$(ls -A /dir/releases/#{'1' * 32})\"").and_return(false)
  end

  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(step_into: 'application')
    runner.converge(described_recipe)
  end

  context 'compiling the test recipe' do
    it 'converges successfully' do
      expect(chef_run).to deploy_application('remote_source')
    end
  end

  context 'stepping into application[remote_source] resource' do
    it 'saves all node attributes' do
      attributes = chef_run.node['applications']['application']['remote_source']
      expect(attributes).not_to be_empty
      expect(attributes.keys.sort)
        .to eq %w(user group path shared_directories source repository migration_command migrate environment
                  revision symlink_before_migrate deploy_action socket)
        .sort
      expect(attributes['deploy_action']).to eq :deploy
      expect(attributes['group']).to eq 'group'
      expect(attributes['migrate']).to eq false
      expect(attributes['path']).to eq '/dir'
      expect(attributes['source']).to eq 'http://example.com/download/file.tgz'
      expect(attributes['shared_directories']).to eq %w(dir1 dir2)
      expect(attributes['socket']).to eq '/dir/shared/var/socket'
      expect(attributes['symlink_before_migrate']).to eq %w(config/database.yml)
      expect(attributes['user']).to eq 'remote_source'
    end

    it 'creates default user' do
      expect(chef_run).to create_user('remote_source')
        .with(supports: { manage_home: true },
              manage_home: true,
              home: '/home/remote_source',
              shell: '/bin/bash')
    end

    it 'creates base directory with permissions' do
      expect(chef_run).to create_directory('/dir')
        .with(
          recursive: true,
          owner: 'remote_source',
          group: 'group')
    end

    it 'creates shared directory' do
      expect(chef_run).to create_directory('/dir/shared')
        .with(
          recursive: true,
          group: 'group',
          user: 'remote_source')
    end

    # As symlink_before_migrate includes config/database.yml by default it must
    # create  shared/config
    it 'creates shared/config' do
      expect(chef_run).to create_directory('/dir/shared/config')
        .with(
          recursive: true,
          group: 'group',
          user: 'remote_source'
        )
    end

    it 'creates shared/var because of socket unix' do
      expect(chef_run).to create_directory('/dir/shared/var')
        .with(
          recursive: true,
          group: 'group',
          user: 'remote_source'
        )
    end

    it 'creates shared directories' do
      %w(dir1 dir2).each do |dir|
        expect(chef_run).to create_directory("/dir/shared/#{dir}")
          .with(
            recursive: true,
            group: 'group',
            user: 'remote_source'
          )
      end
    end

    it 'creates test directory because of before_deploy' do
      expect(chef_run).to create_directory 'test_before_deploy'
    end

    context 'install from remote file' do
      it 'creates releases directory' do
        expect(chef_run).to create_directory('/dir/releases')
          .with(
            recursive: true,
            group: 'group',
            user: 'remote_source'
          )
        expect(chef_run).to create_directory('/dir/releases/' + '1' * 32)
          .with(
            group: 'group',
            user: 'remote_source'
          )
      end

      it 'downloads remote file' do
        expect(chef_run).to create_remote_file('/dir/releases/file.tgz').with(
          source: 'http://example.com/download/file.tgz',
          owner: 'remote_source',
          retries: 5)
      end

      it 'extracts file' do
        code = <<-CODE
            tar xfz /dir/releases/file.tgz --strip-components=1 -C /dir/releases/#{'1' * 32}
            CODE
        expect(chef_run).to run_bash('extract file').with(
          cwd: '/dir/releases',
          code: code,
          user: 'remote_source',
          group: 'group')
      end

      context 'updates shared resources' do
        it 'deletes shared_directories' do
          %w(dir1 dir2).each do |dir|
            expect(chef_run).to delete_directory("/dir/releases/#{'1' * 32}/#{dir}")
              .with(
                recursive: true
              )
          end
        end

        it 'deletes symlinked files' do
          expect(chef_run).to delete_file("/dir/releases/#{'1' * 32}/" + 'config/database.yml')
        end

        it 'creates symlinks of files and directories' do
          %w(dir1 dir2 config/database.yml).each do |res|
            expect(chef_run).to create_link("/dir/releases/#{'1' * 32}/#{res}")
              .with(
                to: "/dir/shared/#{res}",
                owner: 'remote_source',
                group: 'group')
          end
        end

        it 'creates symlink to current release' do
          expect(chef_run).to delete_file('/dir/current')

          expect(chef_run).to create_link('/dir/current')
            .with(
              to: "/dir/releases/#{'1' * 32}",
              owner: 'remote_source',
              group: 'group')
        end
      end
    end
  end
end
