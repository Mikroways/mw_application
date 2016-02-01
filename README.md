# Generic Aplication cookbook

The Application cookbook  `mw_application` is a library cookbook that provides
resource primitives (LWRP) for use in recipes. It also provides with helper methods
to easily define new custom application resources

Requirements
------------

* Chef 12+

Platform support
----------------

The following platforms have been tested with test kitchen

* Ubuntu 14.04

Cookbook dependencies
---------------------

* ruby_build
* ruby_rbenv

Other cookbooks may be required depending on the platform used:

* apt so packages are updated if ubuntu/debian
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

The `:install action` creates a user and deploys application as that user,
running only before_migrate callback and simplifying the way deploy_revision
resource is used, basically using deployment convention previously described.
It also set node attributes so they can be used using search or reading this
attributes for custom development needs

#### Parameters

- `name` - name of the resource. It will be used as default value for creating
  application ti deploy application as.
- `owner` - user to be created and used to deploy code as.
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
- `before_migrate` -  Proc with custom code to be used as callback to
  `deploy_revision` resource. This callback can use a custom helper named
`application_resource` that will return current resource, this is an application
resource or a custom subclass of it. Inside this Proc, other helpers provided by
deploy resource are available as `new_resource`, `shared_path` and `release_path`


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

    before_migrate do

      rbenv_script "rbenv local" do
        cwd release_path
        rbenv_version application_resource.ruby
        code %{rbenv local #{application_resource.ruby}}
      end

      rbenv_script "bundle update" do
        cwd release_path
        rbenv_version application_resource.ruby
        code %{rbenv bundle install --without development test --deployment}
      end

    end
  end
```

Helpers provided
----------------

This cookbook provides with two helpers to easily extend chef resources for your
custom applications:

### `define_application` helper

This helper is used as a library in your cookbook and for example:

```ruby
  define_application 'my_app' do
    defaults shared_directories: %w(log tmp files public),
             repository: 'https://github.com/user/app.git'

    before_migrate do
      # CUSTOM CODE
    end
  end
```

The above example will create a resource named my_app that can be used in other
cookbooks as:

```ruby
  my_app 'name' do
    path '/opt/application/name'
  end
```

### `define_application ruby` helper

As explained for `application_ruby` resource above this is a specialized version
of the above helper, for ruby applications

