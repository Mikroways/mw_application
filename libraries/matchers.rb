if defined?(ChefSpec)
  if ChefSpec.respond_to?(:define_matcher)
    ChefSpec.define_matcher :application
    ChefSpec.define_matcher :application_ruby
  end

  %i(deploy force_deploy rollback delete).each do |action|
    define_method("#{action}_application") do |name|
      ChefSpec::Matchers::ResourceMatcher.new(:application, action, name)
    end

    define_method("#{action}_application_ruby") do |name|
      ChefSpec::Matchers::ResourceMatcher.new(:application_ruby, action, name)
    end
  end

end
