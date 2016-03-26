define_application 'wordpress' do
  shared_directories  %w(wp-content/languages wp-content/plugins wp-content/themes wp-content/uploads)
  symlink_before_migrate %w(wp-config.php)
  source 'https://wordpress.org/wordpress-4.4.2.tar.gz'

  class_helpers do
    attribute :db_name, kind_of: String, required: true, default: lazy { |resource| resource.name }
    attribute :db_user, kind_of: String, required: true, default: lazy { |resource| resource.name }
    attribute :db_password, kind_of: String
    attribute :db_host, kind_of: String, default: '127.0.0.1'
    attribute :db_prefix, kind_of: String, default: 'wp_'
    attribute :db_charset, kind_of: String, default: 'utf8mb4'
    attribute :db_collate, kind_of: String
    attribute :keys_auth, kind_of: String, required: true
    attribute :keys_secure_auth, kind_of: String, required: true
    attribute :keys_logged_in, kind_of: String, required: true
    attribute :keys_nonce, kind_of: String, required: true
    attribute :salt_auth, kind_of: String, required: true
    attribute :salt_secure_auth, kind_of: String, required: true
    attribute :salt_logged_in, kind_of: String, required: true
    attribute :salt_nonce, kind_of: String, required: true
    attribute :lang, kind_of: String
    attribute :allow_multisite, kind_of: [TrueClass, FalseClass]
    attribute :wp_config_options, kind_of: Hash, default: Hash.new
  end

  before_deploy do

    package application_resource.value_for_platform(
      'debian' => { '< 7' => 'php5-mysql', 'default' => 'php5-mysqlnd' },
      'ubuntu' => { 'default' => 'php5-mysqlnd' },
      'centos' => { '< 7' => 'php-mysql', 'default' => 'php-mysqlnd'} )


    template "#{shared_path}/wp-config.php" do
      source 'wp-config.php.erb'
      owner application_resource.user
      mode '0640'
      variables(
        :db_name           => application_resource.db_name,
        :db_user           => application_resource.db_user,
        :db_password       => application_resource.db_password,
        :db_host           => application_resource.db_host,
        :db_prefix         => application_resource.db_prefix,
        :db_charset        => application_resource.db_charset,
        :db_collate        => application_resource.db_collate,
        :auth_key          => application_resource.keys_auth,
        :secure_auth_key   => application_resource.keys_secure_auth,
        :logged_in_key     => application_resource.keys_logged_in,
        :nonce_key         => application_resource.keys_nonce,
        :auth_salt         => application_resource.salt_auth,
        :secure_auth_salt  => application_resource.salt_secure_auth,
        :logged_in_salt    => application_resource.salt_logged_in,
        :nonce_salt        => application_resource.salt_nonce,
        :lang              => application_resource.lang,
        :allow_multisite   => application_resource.allow_multisite,
        :wp_config_options => application_resource.wp_config_options
      )
    end

  end

end
