require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class ApplicationService < Chef::Resource::LWRPBase
      self.resource_name = :application_service
      provides :application_service

      actions :create
      default_action :create

      attribute :name,  kind_of: String, name_property: true, required: true
      attribute :user, kind_of: String, required: true, default: lazy {|resource| resource.name}
      attribute :path, kind_of: String, required: true
      attribute :command, kind_of: String, required: true
      attribute :environment, kind_of: Hash, default: {}

      # Upstart
      attribute :start_on, kind_of: String, default: "runlevel [2345]"
      attribute :stop_on, kind_of: String, default: "starting rc RUNLEVEL=[016]"
      attribute :respawn, kind_of: [TrueClass, FalseClass], default: true
      attribute :respawn_limit, kind_of: String, default: 'unlimited'
      attribute :pre_start, kind_of: String
      attribute :post_start, kind_of: String
      attribute :pre_stop, kind_of: String
      attribute :post_stop, kind_of: String

      # Systemd
      attribute :after, kind_of: String, default: "network.target"
      attribute :wanted_by, kind_of: String, default: "multi-user.target"
      attribute :respawn, kind_of: [TrueClass, FalseClass], default: true
      attribute :stdout, kind_of: String, default: 'syslog'
      attribute :stderr, kind_of: String, default: 'syslog'
    end
  end
end
