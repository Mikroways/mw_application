if defined?(ChefSpec)
  if ChefSpec.respond_to?(:define_matcher)
    ChefSpec.define_matcher :application
    ChefSpec.define_matcher :application_ruby
  end

  def install_application(name)
    ChefSpec::Matchers::ResourceMatcher.new(:application, :install, name)
  end

  def install_application_ruby(name)
    ChefSpec::Matchers::ResourceMatcher.new(:application_ruby, :install, name)
  end

end
