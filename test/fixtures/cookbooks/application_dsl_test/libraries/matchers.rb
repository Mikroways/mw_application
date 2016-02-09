if defined?(ChefSpec)
  if ChefSpec.respond_to?(:define_matcher)
    ChefSpec.define_matcher :my_app
    ChefSpec.define_matcher :my_ruby_app
  end

  %i(deploy force_deploy rollback delete).each do |action|
    define_method("#{action}_my_app") do |name|
      ChefSpec::Matchers::ResourceMatcher.new(:my_app, action, name)
    end

    define_method("#{action}_my_ruby_app") do |name|
      ChefSpec::Matchers::ResourceMatcher.new(:my_ruby_app, action, name)
    end
  end

end

