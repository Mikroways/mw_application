class Chef
  class Provider
    # Ruby application provider. It will install ruby using rbenv
    # All rbenv cookbooks helpers are provided
    class ApplicationRuby < ApplicationBase
      provides :application_ruby

      def prepare_deployment
        super
        install_ruby
      end

      def install_ruby
        include_recipe 'ruby_rbenv::system_install'
        include_recipe 'ruby_build'

        rbenv_ruby new_resource.ruby

        rbenv_gem 'bundler' do
          rbenv_version new_resource.ruby
        end
      end

      def save_node_attributes
        super
        node.set[new_resource.node_attribute][new_resource.resource_name][new_resource.name]['ruby'] = new_resource.ruby
      end
    end
  end
end
