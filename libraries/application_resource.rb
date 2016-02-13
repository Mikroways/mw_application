require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class Deploy < Chef::Resource
      attr_accessor :application_resource
    end

    class ApplicationBase < Chef::Resource::LWRPBase
      provides :application

      self.resource_name = :application


      actions :deploy, :force_deploy, :rollback, :delete
      default_action :deploy

      attribute :name,  kind_of: String, name_property: true, required: true
      attribute :user, kind_of: String, required: true, default: lazy {|resource| resource.name}
      attribute :group, kind_of: String
      attribute :path, kind_of: String, required: true
      attribute :shared_directories, kind_of: Array, default: []
      attribute :repository, kind_of: String, required: true
      attribute :revision, kind_of: String
      attribute :symlink_before_migrate, kind_of: Array, default: %w(config/database.yml)
      attribute :deploy_action, kind_of: Symbol, default: :deploy, is: [:deploy, :force_deploy, :rollback]
      attribute :node_attribute, kind_of: String, default: 'applications'
      attribute :variables, kind_of: Hash, default: {}
      attribute :environment, kind_of: Hash
      attribute :migrate, kind_of: [TrueClass, FalseClass], default: false
      attribute :migration_command, kind_of: String


      def before_migrate(arg=nil, &block)
        arg ||= block
        set_or_return(:before_migrate, arg, :kind_of => [Proc, String])
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

      def set_provider(provider)
        @provider = Chef::Provider::ApplicationBase
      end

      def set_defaults(attributes)
        Hash[attributes.map{|n,v| ["@#{n}",v] }].each(&method(:instance_variable_set))
      end

      def set_before_migrate(&block)
        @before_migrate = block
      end

      # Creates a class dinamically as subclass of self and delegates methods:
      #   #set_defaults(args)
      #   #set_before_migrate(&block)
      #   #set_provider(provider)
      #
      # using ApplicationDelegator class (Delegator pattern) and allowing this method to
      # dinamically define resources with a custom DSL like:
      #
      # Chef::Resource::Application.define 'my_application', do
      #   defaults  shared_directories: %w(log tmp files),
      #             repository: 'https://github.com/user/application.git',
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

          class  << self

            def set_define_block(&block)
              @define_block = block
            end

            def define_block
              @define_block
            end

          end

          def initialize(name, run_context=nil)
            super
            set_provider nil
            delegate_initialization
          end

        end
        klass.resource_name = name.to_sym
        klass.set_define_block(&block)
        klass_name = Chef::Mixin::ConvertToClassName.convert_to_class_name(name)
        self.const_set klass_name, klass unless defined?(klass_name)
        klass
      end

      def delegate_initialization
        ApplicationDelegator.new(self).instance_eval(&self.class.define_block)
      end

    end

    class ApplicationDelegator < SimpleDelegator
      def defaults(attributes)
        set_defaults(attributes)
      end

      def before_migrate(&block)
        set_before_migrate(&block)
      end

      def provider(provider)
        set_provider(provider)
      end
    end

  end
end
