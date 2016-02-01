class Chef
  class Provider
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

    end
  end
end
