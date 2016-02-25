module Application
  module Helper
    # Custom ruby helpers used by common ruby applications as:
    # * rails application environment variables
    # * default rvbenv path
    # * default rvbenv root
    module Ruby
      def application_rails_environment
        application_ruby_environment.merge 'RAILS_ENV' => 'production'
      end

      def application_ruby_environment
        {
          'RAILS_ENV' => 'production',
          'RBENV_ROOT' => rbenv_root,
          'PATH' => "#{rbenv_root}/bin:#{rbenv_root}/shims:#{default_path}"
        }
      end

      def default_path
        '/usr/local/bin:/usr/bin:/bin'
      end

      def rbenv_root
        node['rbenv']['root_path']
      end
    end
  end
end
