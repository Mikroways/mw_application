require 'chef/provider/lwrp_base'
class Chef
  class Provider
    class Deploy < Chef::Provider
      attr_accessor :application_resource

      def load_current_resource_with_application_resource
        load_current_resource_without_application_resource
        @application_resource = @new_resource.application_resource if @new_resource.respond_to?(:application_resource)
      end

      alias_method :load_current_resource_without_application_resource, :load_current_resource
      alias_method :load_current_resource, :load_current_resource_with_application_resource

    end

    class ApplicationBase < Chef::Provider::LWRPBase
      attr_accessor :shared_path, :socket
      provides :application

      use_inline_resources

      def load_current_resource
        super
        @shared_path = @new_resource.shared_path
        @socket = @new_resource.socket
      end

      action :install do

        prepare_deployment

        application_resource = new_resource

        d = deploy_revision new_resource.name do
          user new_resource.owner
          repository new_resource.repository
          revision new_resource.revision
          deploy_to new_resource.path
          purge_before_symlink new_resource.shared_directories
          symlinks symlinks_hash
          symlink_before_migrate symlink_before_migrate_hash
          before_migrate new_resource.before_migrate
          action new_resource.deploy_action
          migrate new_resource.migrate
          migration_command new_resource.migration_command
        end

        d.application_resource = application_resource


      end

      def symlinks_hash
        Hash[new_resource.shared_directories.map{|d| [d,d]}] if new_resource.shared_directories
      end

      def symlink_before_migrate_hash
        Hash[new_resource.symlink_before_migrate.map{|d| [d,d]}] if new_resource.symlink_before_migrate
      end


      def save_node_attributes
        node.set[new_resource.node_attribute] = { new_resource.resource_name => {} }
        node.set[new_resource.node_attribute][new_resource.resource_name][new_resource.name] = {
          owner: new_resource.owner,
          path: new_resource.path,
          shared_directories: new_resource.shared_directories,
          repository: new_resource.repository,
          revision: new_resource.revision,
          symlink_before_migrate: new_resource.symlink_before_migrate,
          deploy_action: new_resource.deploy_action,
          socket: socket
        }
      end

      def prepare_deployment
        save_node_attributes

        user new_resource.owner do
          supports    :manage_home => true
          manage_home true
          home        "/home/#{new_resource.owner}"
          shell       '/bin/bash'
        end

        directory new_resource.path do
          recursive true
          mode '0750'
          group new_resource.group
          user new_resource.owner
        end

        ( [shared_path] +
         (Array(new_resource.symlink_before_migrate).map {|x| "#{shared_path}/#{x}"} + [socket]).map {|x| ::File.dirname x} +
        new_resource.shared_directories.map {|x| "#{shared_path}/#{x}"}). each do |dir|
          directory dir do
            recursive true
            user new_resource.owner
          end
        end
      end

    end
  end
end
