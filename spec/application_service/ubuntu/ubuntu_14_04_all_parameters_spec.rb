#
# Cookbook Name:: mw_application
# Spec:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'application_service_test::all_parameters' do

  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      platform: 'ubuntu',
      version: '14.04',
      step_into: 'application_service')
    runner.converge(described_recipe)
  end

  context 'when template sintax is ok' do
    before do
      stub_command("/bin/init-checkconf /etc/init/all_params.conf").and_return(true)
      stub_command("/bin/init-checkconf /etc/init/no_respawn.conf").and_return(true)
    end


    context 'compiling the test recipe' do
      it 'converges successfully' do
        expect(chef_run).to create_application_service('all_params')
        expect(chef_run).to create_application_service('no_respawn')
      end
    end

    context 'stepping into application_service[all_params] resource' do
      let(:all_params_tpl) do
<<CONTENT
start on started networking
stop on stopped networking
respawn
respawn limit 2 10
env HOME='/home/some_user'
env PATH='/usr/bin'
setuid some_user
chdir /tmp
pre-start exec pre start command
post-start exec post start command
exec a command
pre-stop exec pre stop command
post-stop exec post stop command
CONTENT
      end

      it 'creates template /etc/init/all_params.conf' do
        expect(chef_run).to create_template('all_params :create /etc/init/all_params.conf')
      end

      it 'creates template with expected content' do
        expect(chef_run).to render_file('all_params :create /etc/init/all_params.conf')
        .with_content { |content| expect(content.squeeze "\n").to eq all_params_tpl }
      end

    end

    context 'stepping into application_service[no_respawn] resource' do
      let(:no_respawn_tpl) do
<<CONTENT
start on runlevel [2345]
stop on starting rc RUNLEVEL=[016]
setuid no_respawn
chdir /tmp
exec a command
CONTENT
      end

      it 'creates template /etc/init/no_respawn.conf' do
        expect(chef_run).to create_template('no_respawn :create /etc/init/no_respawn.conf')
      end

      it 'creates template with expected content' do
        expect(chef_run).to render_file('no_respawn :create /etc/init/no_respawn.conf')
        .with_content { |content| expect(content.squeeze "\n").to eq no_respawn_tpl }
      end

    end
  end

end
