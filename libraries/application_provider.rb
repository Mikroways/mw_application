require 'chef/provider/lwrp_base'
class Chef
  class Provider
    # Monkey patch Deploy Provider resource adding application_rsource
    # attribute to be available inside custom hooks
    class Deploy < Chef::Provider
      attr_accessor :application_resource

      def load_current_resource_with_application_resource
        load_current_resource_without_application_resource
        @application_resource = @new_resource.application_resource if
          @new_resource.respond_to?(:application_resource)
      end

      alias_method :load_current_resource_without_application_resource, :load_current_resource
      alias_method :load_current_resource, :load_current_resource_with_application_resource
      include Chef::DSL::IncludeRecipe
    end

    # Application base class that will create user, required directories
    # as a deploy deploy resource
    class ApplicationBase < Chef::Provider::LWRPBase
      attr_accessor :shared_path, :socket, :application_resource, :use_remote_file, :source_file,
                    :release_slug, :release_dir, :release_path
      provides :application
      use_inline_resources

      def load_current_resource
        super
        @current_resource = Chef::Resource::ApplicationBase.new(@new_resource.name)
        @shared_path = @new_resource.shared_path
        @socket = @new_resource.socket
        @application_resource = @new_resource
        @use_remote_file = @new_resource.repository.nil?
        if @use_remote_file
          @release_dir = "#{@new_resource.path}/releases"
          @source_file = "#{release_dir}/#{::File.basename(URI(new_resource.source).path)}"
          @release_slug = find_release_slug
          @release_path = "#{@release_dir}/#{release_slug}"
        end
      end

      def define_resource_requirements
        requirements.assert(:rollback, :force_deploy, :delete) do |a|
          a.assertion do
            @new_resource.source.nil?
          end
          a.failure_message(Chef::Exceptions::UnsupportedAction,
                            'Application cannot be rolled back nor force deployed when installed from source')
        end
        requirements.assert(:rollback, :delete) do |a|
          a.assertion do
            node[@new_resource.node_attribute] &&
              node[@new_resource.node_attribute][@new_resource.resource_name] &&
              node[@new_resource.node_attribute][@new_resource.resource_name][@new_resource.name]
          end
          a.failure_message(Chef::Exceptions::UnsupportedAction,
                            'Application cannot be rolled back nor deleted when not deployed before')
        end

        requirements.assert(:all_actions) do |a|
          a.assertion do
            !@new_resource.repository.nil? && @new_resource.source.nil? ||
              @new_resource.repository.nil? && !@new_resource.source.nil?
          end
          a.failure_message(Chef::Exceptions::InvalidKeyAttribute,
                            'Application deployment conflict with source or repository attributes')
        end

        requirements.assert(:all_actions) do |a|
          a.assertion do
            @use_remote_file && md5_hash?(@release_slug) || !@use_remote_file
          end
          a.failure_message(Chef::Exceptions::InvalidKeyAttribute,
                            "Invalid release_slug:#{@release_slug} for #{@new_resource.source}")
        end
      end

      action :deploy do
        deploy_with_action :deploy
      end

      action :force_deploy do
        deploy_with_action :force_deploy
      end

      action :rollback do
        deploy_resource :rollback
      end

      action :delete do
        delete_application
      end

      def symlinks_hash
        Hash[new_resource.shared_directories.map { |d| [d, d] }] if
          new_resource.shared_directories
      end

      def symlink_before_migrate_hash
        Hash[new_resource.symlink_before_migrate.map { |d| [d, d] }] if
          new_resource.symlink_before_migrate
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
          source: new_resource.source,
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
          supports manage_home: true
          manage_home true
          home "/home/#{new_resource.user}"
          shell '/bin/bash'
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

        directories += other_directories.map { |x| ::File.dirname x }

        directories += new_resource.shared_directories.map { |x| "#{shared_path}/#{x}" }

        directories.uniq.each do |dir|
          d = directory dir do
            recursive true
          end
          d.user new_resource.user
          d.group new_resource.group
        end

        instance_eval(&new_resource.before_deploy) if new_resource.before_deploy
      end

      def deploy_with_action(deploy_action)
        prepare_deployment
        deploy_resource deploy_action
      end

      def deploy_resource(deploy_action)
        if use_remote_file
          deploy_from_remote_file_resource deploy_action
        else
          deploy_from_deploy_resource deploy_action
        end
      end

      def cache_path
        "#{shared}/cache"
      end

      def deploy_from_remote_file_resource(_deploy_action)
        prepare_directory_structure

        install_remote_source

        update_shared_directories

        link_current_release_to_production
      end

      def deploy_from_deploy_resource(deploy_action)
        application_resource = new_resource

        d = deploy new_resource.name

        d.repository new_resource.repository
        d.revision new_resource.revision
        d.deploy_to new_resource.path
        d.purge_before_symlink new_resource.shared_directories
        d.symlinks symlinks_hash
        d.symlink_before_migrate symlink_before_migrate_hash
        d.before_migrate new_resource.before_migrate
        d.before_restart new_resource.before_restart
        d.action deploy_action
        d.migrate new_resource.migrate
        d.migration_command new_resource.migration_command
        d.environment new_resource.environment
        d.provider Chef::Provider::Deploy::Revision
        d.user new_resource.user
        d.group new_resource.group
        d.application_resource = application_resource
      end

      # Dlete attributes from node
      def delete_application
        node.rm(new_resource.node_attribute, new_resource.resource_name, new_resource.name)
      end

      private

      def find_release_slug
        if !::File.exist?(source_file)
          package 'curl' do
            action :nothing
          end.run_action(:install)

          shell_out!("curl -s '#{@new_resource.source}' | md5sum | grep --only-matching -m 1 '^[0-9a-f]*'")
            .stdout.chomp("\n")
        else
          shell_out!("md5sum #{source_file} | grep --only-matching -m 1 '^[0-9a-f]*'")
            .stdout.chomp("\n")
        end
      end

      def md5_hash?(string)
        string =~ /^[0-9a-f]{32}$/
      end

      def prepare_directory_structure
        d_release_dir = directory release_dir do
          recursive true
        end
        d_release_dir.owner new_resource.user
        d_release_dir.group new_resource.group

        d_releases = directory release_path
        d_releases.owner new_resource.user
        d_releases.group new_resource.group
      end

      def install_remote_source
        remote = remote_file source_file do
          retries 5
          not_if "test -s #{source_file}"
        end
        remote.source new_resource.source
        remote.owner new_resource.user

        source = source_file
        extract_path = release_path
        script = bash 'extract file' do
          cwd ::File.dirname(source_file)
          code <<-EOH
            tar xfz #{source} --strip-components=1 -C #{extract_path}
          EOH
          not_if "test \"$(ls -A #{extract_path})\"" # test "$(ls -A /dir)" is true when /dir has files
        end
        script.user new_resource.user
        script.group new_resource.group
      end

      def update_shared_directories
        new_resource.shared_directories.each do |dir|
          directory "#{release_path}/#{dir}" do
            recursive true
            action :delete
            not_if "test -L #{release_path}/#{dir}"
          end
        end

        new_resource.symlink_before_migrate.each do |file|
          file "#{release_path}/#{file}" do
            action :delete
            not_if "test -L #{release_path}/#{file}"
          end
        end

        (new_resource.shared_directories +
          new_resource.symlink_before_migrate).each do |resource|
          l = link "#{release_path}/#{resource}" do
            to "#{shared_path}/#{resource}"
          end
          l.owner new_resource.user
          l.group new_resource.group
        end
      end

      def link_current_release_to_production
        l = link new_resource.current_path
        l.to release_path
        l.owner new_resource.user
        l.group new_resource.group
      end
    end
  end
end
