def define_application(name, &block)
  Chef::Resource::ApplicationBase.define name, &block
end

def define_application_ruby(name, &block)
  Chef::Resource::ApplicationRuby.define name, &block
end
