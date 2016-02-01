require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class Deploy < Chef::Resource
      attr_accessor :application_resource
    end

    class ApplicationBase < Chef::Resource::LWRPBase
      provides :application

      self.resource_name = :application

      actions :install
      default_action :install

      attribute :name,  kind_of: String, name_property: true, required: true
      attribute :owner, kind_of: String, required: true, default: lazy {|resource| resource.name}
      attribute :path, kind_of: String, required: true
      attribute :shared_directories, kind_of: Array, default: []
      attribute :repository, kind_of: String, required: true
      attribute :revision, kind_of: String
      attribute :symlink_before_migrate, kind_of: Array, default: %w(config/database.yml)
      attribute :deploy_action, kind_of: Symbol, default: :deploy, is: [:deploy, :force_deploy, :rollback]
      attribute :node_attribute, kind_of: String, default: 'applications'
      attribute :database, kind_of: Hash, required: true
      attribute :before_migrate, kind_of: [Proc, String]


      def shared_path
        "#{path}/shared"
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
      #       user application_resource.owner
      #       command "some command to update application"
      #       action :nothing
      #     end
      #     file "#{release_path}/config/database.yml" do
      #       owner application_resource.owner
      #       mode '0640'
      #       content application_resource.database.to_yaml
      #       sensitive true
      #       notifies :run, "script[update something]"
      #     end
      ##     
      #   end
      def self.define(name, &block)
        klass = Class.new(self) do
          self.resource_name = name.to_sym
          provides name.to_sym

          @@define_block = nil

          def self.set_define_block(&block)
            @@define_block = block
          end

          def self.define_block
            @@define_block
          end

          def initialize(name, run_context=nil)
            super
            set_provider nil
            ApplicationDelegator.new(self).instance_eval(&self.class.define_block)
          end

        end
        klass.set_define_block(&block)
        Object.const_set Chef::Mixin::ConvertToClassName.convert_to_class_name(name), klass
        klass
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
