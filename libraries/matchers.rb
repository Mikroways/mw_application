if defined?(ChefSpec)
  def install_application(name)
    ChefSpec::Matchers::ResourceMatcher.new(:application, :install, name)
  end

  def install_application_ruby(name)
    ChefSpec::Matchers::ResourceMatcher.new(:application_ruby, :install, name)
  end

  def create_application_service(name)
    ChefSpec::Matchers::ResourceMatcher.new(:application_service, :create, name)
  end
end
