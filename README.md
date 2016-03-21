# Generic Aplication cookbook

[![Build Status](https://travis-ci.org/Mikroways/mw_application.svg?branch=master)](https://travis-ci.org/Mikroways/mw_application) [![Cookbook Version](https://img.shields.io/cookbook/v/mw_application.svg)](https://supermarket.chef.io/cookbooks/mw_application)

The Application cookbook  `mw_application` is a library cookbook that provides
resource primitives (LWRP) for use in recipes to easily deploy applications. It also provides with helper methods
to easily define new custom application resources

Requirements
------------

* Chef 12+

Platform support
----------------

The following platforms have been tested with test kitchen

* Debian 7
* Ubuntu 14.04
* CentOS 6.7
* CentOS 7.1


Cookbook dependencies
---------------------

* ruby_build
* ruby_rbenv

Other cookbooks may be required depending on the platform used:

* apt/yum so packages are updated if ubuntu/debian/centos/rhel
* git if your application will be deployed using git

Usage
-----

Place a dependency on the mw_application cookbook in your cookbook's metadata.rb

```ruby
  depends 'mw_application', '~> 0.1.0'
```

Then, in a recipe:

```ruby
  application 'my_app' do
    path '/opt/applications/my_app'
    database database_content.gt
    shared_directories %w(log tmp files public)
    repository 'https://github.com/user/my_app.git'
    revision 'master'
  end
```

or if it is a ruby application:


```ruby
  application_ruby 'my_app' do
    path '/opt/applications/my_app'
    database database_content.gt
    shared_directories %w(log tmp files public)
    repository 'https://github.com/user/my_app.git'
    revision 'master'
    ruby '2.2.4'
  end
```

Last example installs ruby 2.2.4 using ruby_rbenv and ruby_build
cookbooks. In both examples application is installed as a user with resource
name, this is, `my_app` user will be created and application will be deployed as
this user.

Resources overview
------------------

Before describing exposed resources, is necessary to describe deployment
conventions assumed:

* An application will be deployed as a user, meaning that if more than one
  application will be deployed, each one can be deployed as different users. You
  can deploy more than one application with the same user
* Symlinks are specified as array instead of a hash as deploy resource defines.
  This is because each release file that will be shared, by convention, will be
  in the same directory under shared directory
* Shared directories must be specified so they are first purged using
  `purge_before_symlink` after cloning repository and this attribute is not
  necessary in application resource



### application

This resource manages the basic deployment of an application owned by a specific user.
The implementation of this resource provider is using original chef resources
like user, directory and deploy_revision. The implementation of the application
resource is a wrapper resource that avoids repeating code for user creation and
shared directories structure creation.

The `:deploy action` creates a user and deploys application as that user,
running before_deploy callback and simplifying the way deploy_revision
resource is used, basically using deployment convention previously described.
It also set node attributes so they can be used using search or reading this
attributes for custom development needs.

#### Actions

Actions are the same for original chef deploy resource:

- `:deploy`
- `:force_deploy`
- `:rollback`

An additional `:delete` action is provided to remove saved node attributes, but
it will not delete installed application from server. This action must be run
manually.

#### Parameters

- `name` - name of the resource. It will be used as default value for creating
  application ti deploy application as.
- `user` - user to be created and used to deploy code as.
- `path` - path to deploy code using `deploy_revision` chef resource
- `shared_directories` - array of directories to be created in shared directory
  and purged after cloning code
- `repository` - url of repository
- `revision` - reivsion of the application to be deployed
- `symlink_before_migrate` - files to be symlinked to shared directory before
  running `migration_command`
- `deploy_action` - `deploy_revision` action to be used. Defaults to `:deploy`
- `node_attribute` - name of node's attribute to save this parameters after
  deployment
- `database` - hash to be used for custom code as developer wants. For example,
  dump hash as YAML file
- `before_deploy` -  Proc with custom code to be used as callback to build
  proper environment so deployment will be easier to manage. This callback can use
  a custom helper named `application_resource` that will return current resource,
  this is an application resource or a custom subclass of it. Inside this Proc,
  other helpers provided by deploy resource are available as `new_resource`,
  `shared_path` and `release_path`
- `before_migrate` -  Proc with custom code to be used as callback to
  `deploy_revision` resource. This callback can use a custom helper named
  `application_resource` that will return current resource, this is an application
  resource or a custom subclass of it. Inside this Proc, other helpers provided by
  deploy resource are available as `new_resource`, `shared_path` and `release_path`
- `before_restart` -  Proc with custom code to be used as callback to
  `deploy_revision` resource. This callback can use a custom helper named
  `application_resource` as explained for `before_migrate`
- `environment`: environment variables specified as hash of key values. Defaults
  to nil
- `migration_command`: string with command to be run. Default nil. Command will
  be run with specified environment
- `migrate`: boolean indicating if migration_command should be run. Default to
  false


### application_ruby

This is a specialized version of the above resource, but it allows to specify a
ruby version and it will installs it before proceding. Also it will provide more
helpers: the ones provided by ruby_rbenv cookbook.

For example:

```ruby
  application_ruby 'my_app' do
    path '/opt/applications/my_app'
    database database_content.gt
    shared_directories %w(log tmp files public)
    repository 'https://github.com/user/my_app.git'
    revision 'master'

    ruby '2.2.4'

    before_deploy do
      file "#{shared_path}/config/database.yml" do
        ...
      end
    end

    before_migrate do

      # Will be run as root
      rbenv_script "rbenv local" do
        cwd release_path
        rbenv_version application_resource.ruby
        code %{rbenv local #{application_resource.ruby}}
      end

      # Will be run as root sharing gems
      rbenv_script "bundle update" do
        cwd release_path
        rbenv_version application_resource.ruby
        code %{rbenv bundle install --without development test --frozen}
      end

    end
  end
```

Some tips when coding `callbacks` blocks
--------------------------------------------
This applies to `before_deploy`, `before_migrate` and `before_restart` callbacks

Inside this block you can use any resource chef knows, but some useful helpers
are not available inside `Chef::Provider` class. This is the case of
`value_for_platform` or `value_for_platform_family`. When you need this helpers
inside `before_migrate` block you can call them via `application_resource` or `new_resource`
because this DSL methods are included by `Chef::Resource` class. 

```ruby

new_resource.value_for_platform_family debian: 'git-core'

```

Helpers provided
----------------

This cookbook provides with two helpers to easily extend chef resources for your
custom applications:

### `define_application` helper

This helper is used as a library in your cookbook and for example:

```ruby
  define_application 'my_app' do
    # Set default values
    shared_directories %w(log tmp files public),
    repository 'https://github.com/user/app.git'

    class_helpers do
      attribute :db_name, kind_of: String, required: true, default: lazy { |resource| resource.name }
      attribute :db_user, kind_of: String, default: lazy { |resource| resource.name }
      attribute :db_password, kind_of: String
      attribute :db_host, kind_of: String, default: '127.0.0.1'
      attribute :db_adapter, kind_of: String, required: true
    end

    helpers do
      def my_helper
      end
    end

    before_deploy do
      # CUSTOM CODE
      # application_resource.my_helper can be used
    end

    before_migrate do
      # CUSTOM CODE
      # application_resource.my_helper can be used
    end

    before_restart do
      # CUSTOM CODE
      # application_resource.my_helper can be used
    end
  end
```

*Take a look at the custom helper defined. It can be accessed via `application_resource`*

The above example will create a resource named my_app that can be used in other
cookbooks as:

```ruby
  my_app 'name' do
    path '/opt/application/name'
    db_adapter 'sqlite'
  end
```

### `define_application ruby` helper

As explained for `application_ruby` resource above this is a specialized version
of the above helper, for ruby applications

