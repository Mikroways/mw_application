def install_rbenv_ruby(resource_name)
  ChefSpec::Matchers::ResourceMatcher.new(:rbenv_ruby, :install, resource_name)
end

