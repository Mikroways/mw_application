require 'chef/provider/lwrp_base'
class Chef
  class Provider
    class ApplicationService < Chef::Provider::LWRPBase
      provides :application_service

      use_inline_resources
      action :create do
        raise 'Provider not available for your platform'
      end
    end
  end
end
