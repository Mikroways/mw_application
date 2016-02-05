require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'support/matchers'

at_exit { ChefSpec::Coverage.report! }
