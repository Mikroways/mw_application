class Chef
  class Provider
    class ApplicationServiceUpstart < ApplicationService
      if defined?(provides) # foodcritic ~FC023
        provides :application_service, os: 'linux' do
          Chef::Platform::ServiceHelpers.service_resource_providers.include?(:upstart) &&
            !Chef::Platform::ServiceHelpers.service_resource_providers.include?(:redhat)
        end

        action :create do
          template "#{new_resource.name} :create /etc/init/#{new_resource.name}.conf" do
            path "/etc/init/#{new_resource.name}.conf"
            source 'upstart/application.erb'
            owner 'root'
            group 'root'
            mode '0644'
            variables(
              user: new_resource.user,
              path: new_resource.path,
              command: new_resource.command,
              environment: new_resource.environment,
              start_on: new_resource.start_on,
              stop_on: new_resource.stop_on,
              respawn: new_resource.respawn,
              respawn_limit: new_resource.respawn_limit,
              pre_start: new_resource.pre_start,
              post_start: new_resource.post_start,
              pre_stop: new_resource.pre_stop,
              post_stop: new_resource.post_stop
            )
            cookbook 'mw_application'
            action :create
          end

          ruby_block 'fail' do
            block { raise "Upstart script for /etc/init/#{new_resource.name}.conf failed" }
            action :nothing
          end

          file "#{new_resource.name} :delete /etc/init/#{new_resource.name}.conf syntax error" do
            path "/etc/init/#{new_resource.name}.conf"
            action :delete
            not_if "/bin/init-checkconf /etc/init/#{new_resource.name}.conf"
            notifies :run, 'ruby_block[fail]', :immediate
          end
        end
      end
    end
  end
end
