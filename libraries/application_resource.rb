require 'chef/resource/lwrp_base'

class Chef
  class Resource
    # Deploy resource monkey patched to add application_resource accessor
    class Deploy < Chef::Resource
      attr_accessor :application_resource
    end

    # Application base class that wraps the deployment of applications
    # creating user & directories for application
    class ApplicationBase < Chef::Resource::LWRPBase
      provides :application

      self.resource_name = :application

      actions :deploy, :force_deploy, :rollback, :delete
      default_action :deploy

      attribute :name, kind_of: String, name_property: true, required: true
      attribute :user, kind_of: String, required: true, default: lazy { |resource| resource.name }
      attribute :group, kind_of: String
      attribute :path, kind_of: String, required: true
      attribute :shared_directories, kind_of: Array, default: []
      attribute :repository, kind_of: String, required: true
      attribute :revision, kind_of: String
      attribute :symlink_before_migrate, kind_of: Array, default: %w(config/database.yml)
      attribute :deploy_action, kind_of: Symbol, default: :deploy, is: [:deploy, :force_deploy, :rollback]
      attribute :node_attribute, kind_of: String, default: 'applications'
      attribute :environment, kind_of: Hash
      attribute :migrate, kind_of: [TrueClass, FalseClass], default: false
      attribute :migration_command, kind_of: String

      def before_deploy(arg = nil, &block)
        arg ||= block
        set_or_return(:before_deploy, arg, kind_of: Proc)
      end

      def before_migrate(arg = nil, &block)
        arg ||= block
        set_or_return(:before_migrate, arg, kind_of: [Proc, String])
      end

      def before_restart(arg = nil, &block)
        arg ||= block
        set_or_return(:before_restart, arg, kind_of: [Proc, String])
      end

      def shared_path
        "#{path}/shared"
      end

      def current_path
        "#{path}/current"
      end

      def socket
        "#{shared_path}/var/socket"
      end

      # Subclasses must return expected provider if changes from default application_provider
      def application_provider
        Chef::Provider::ApplicationBase
      end

      # Creates a class dinamically as subclass of self and delegates methods
      # using ApplicationDelegator class (Delegator pattern) and allowing this method to
      # dinamically define resources with a custom DSL like:
      #
      # Chef::Resource::Application.define 'my_application', do
      #   shared_directories %w(log tmp files)
      #   repository 'https://github.com/user/application.git'
      #   before_migrate do
      #     execute "update something" do
      #       cwd release_path
      #       user application_resource.user
      #       command "some command to update application"
      #       action :nothing
      #     end
      #     file "#{release_path}/config/database.yml" do
      #       owner application_resource.user
      #       mode '0640'
      #       content application_resource.database.to_yaml
      #       sensitive true
      #       notifies :run, "script[update something]"
      #     end
      ##
      #   end
      def self.define(name, &block)
        klass = Class.new(self) do
          provides name.to_sym

          class << self
            def set_define_block(&block)
              @define_block = block
            end

            attr_reader :define_block
          end

          def initialize(name, run_context = nil)
            super
            @provider = application_provider
            delegate_initialization
          end
        end
        klass.resource_name = name.to_sym
        klass.set_define_block(&block)
        klass_name = Chef::Mixin::ConvertToClassName.convert_to_class_name(name)
        const_set klass_name, klass unless defined?(klass_name)
        klass
      end

      def delegate_initialization
        ApplicationDelegator.new(self).instance_eval(&self.class.define_block)
      end
    end

    # Custom helper class to use as simple delegator
    class ApplicationDelegator < SimpleDelegator

      def class_helpers(&block)
        __getobj__.class.instance_eval(&block)
      end

      def helpers(&block)
        __getobj__.instance_eval(&block)
      end
    end
  end
end
