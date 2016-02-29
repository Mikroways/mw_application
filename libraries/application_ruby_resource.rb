class Chef
  class Resource
    # Ruby application resource. It must specify ruby version to install
    class ApplicationRuby < ApplicationBase
      include ::Application::Helper::Ruby
      provides :application_ruby

      self.resource_name = :application_ruby

      attribute :ruby, kind_of: String, required: true

      def application_provider
        Chef::Provider::ApplicationRuby
      end
    end
  end
end
