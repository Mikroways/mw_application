#
# Cookbook Name:: mw_application
# Spec:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'application_service_test::default' do

  let(:chef_run) do
    runner = ChefSpec::ServerRunner.new(step_into: 'application_service')
    runner.converge(described_recipe)
  end

  context 'compiling the test recipe' do

    it 'raise an exeption' do
      expect{ chef_run }.to raise_error(RuntimeError)
    end

  end

end
