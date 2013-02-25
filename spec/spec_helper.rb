ENV["RAILS_ENV"] = 'test'
require File.expand_path("../dummy_app/config/environment.rb",  __FILE__)
require 'bundler/setup'
require 'rspec/rails'
require 'statify'

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # config.treat_symbols_as_metadata_keys_with_true_values = true
  # config.run_all_when_everything_filtered = true
  # config.filter_run :focus
  config.infer_base_class_for_anonymous_controllers = false
#   config.before :suite do
#     # ActiveRecord::Migration.verbose = true
#     # ActiveRecord::Base.logger = Logger.new(nil)

#     # ActiveRecord::Migrator.migrate(File.expand_path("spec/dummy_app/db/migrate/20130222234253_create_dummy_models.rb"))

# # class ActiveSupport::TestCase
# #   self.use_transactional_fixtures = true
# #   self.use_instantiated_fixtures  = false
# # end

#     # We want to stub all instances of statsd
#     # Statsd.any_instance.stub(:count => true, :timing => true, :increment => true)
#   end
  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
