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
      include Chef::DSL::IncludeRecipe
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

      action :deploy do
        deploy_with_action :deploy
      end

      action :force_deploy do
        deploy_with_action :force_deploy
      end

      action :rollback do
        raise 'Application cannot be rolled back if not deployed before' unless
          node[new_resource.node_attribute][new_resource.resource_name][new_resource.name]
        deploy_resource :rollback
      end

      action :delete do
        raise 'Application cannot be deleted if not deployed before' unless
          node[new_resource.node_attribute][new_resource.resource_name][new_resource.name]
        delete_application
      end

      def symlinks_hash
        Hash[new_resource.shared_directories.map{|d| [d,d]}] if new_resource.shared_directories
      end

      def symlink_before_migrate_hash
        Hash[new_resource.symlink_before_migrate.map{|d| [d,d]}] if new_resource.symlink_before_migrate
      end


      def save_node_attributes
        node.set[new_resource.node_attribute] = { new_resource.resource_name => {} } unless
          node[new_resource.node_attribute]
        node.set[new_resource.node_attribute][new_resource.resource_name][new_resource.name] = {
          user: new_resource.user,
          group: new_resource.group,
          path: new_resource.path,
          environment: new_resource.environment,
          shared_directories: new_resource.shared_directories,
          repository: new_resource.repository,
          revision: new_resource.revision,
          symlink_before_migrate: new_resource.symlink_before_migrate,
          deploy_action: new_resource.deploy_action,
          migrate: new_resource.migrate,
          migration_command: new_resource.migration_command,
          socket: socket
        }
      end

      def prepare_deployment
        save_node_attributes

        user new_resource.user do
          supports    :manage_home => true
          manage_home true
          home        "/home/#{new_resource.user}"
          shell       '/bin/bash'
        end

        base_dir = directory new_resource.path do
          recursive true
          mode '0750'
        end

        base_dir.user new_resource.user
        base_dir.group new_resource.group

        directories = Array(shared_path)

        other_directories = Array(new_resource.symlink_before_migrate).map do |x|
          "#{shared_path}/#{x}"
        end
        other_directories << socket

        directories += other_directories.map {|x| ::File.dirname x}

        directories += new_resource.shared_directories.map {|x| "#{shared_path}/#{x}"}

        directories.uniq.each do |dir|
          d = directory dir do
            recursive true
          end
          d.user new_resource.user
        end
      end

      def deploy_with_action(deploy_action)
        prepare_deployment
        deploy_resource deploy_action
      end

      def deploy_resource(deploy_action)
        application_resource = new_resource

        d = deploy new_resource.name do
          repository new_resource.repository
          revision new_resource.revision
          deploy_to new_resource.path
          purge_before_symlink new_resource.shared_directories
          symlinks symlinks_hash
          symlink_before_migrate symlink_before_migrate_hash
          before_migrate new_resource.before_migrate
          action deploy_action
          migrate new_resource.migrate
          migration_command new_resource.migration_command
          environment new_resource.environment
          provider Chef::Provider::Deploy::Revision
        end

        d.user new_resource.user
        d.application_resource = application_resource

      end

      # Dlete attributes from node
      def delete_application
        node.rm(new_resource.node_attribute,new_resource.resource_name,new_resource.name)
      end


    end
  end
end
