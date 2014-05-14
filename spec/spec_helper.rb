ENV["RAILS_ENV"] ||= 'test'

require 'factory_girl'
require 'database_cleaner'
require 'devise'
require 'engine_cart'
EngineCart.load_application!

require 'rspec/rails'
require 'rspec/autorun'
# require 'capybara/poltergeist'
# Capybara.javascript_driver = :poltergeist
# Capybara.default_wait_time = 5


if ENV['COVERAGE']
  require 'simplecov'

  ENGINE_ROOT = File.expand_path('../..', __FILE__)

  # Out of the box, SimpleCov was looking at file in ENGINE_ROOT/spec/internal;
  # After all that was where Rails was pointed at.
  SimpleCov.root(ENGINE_ROOT)
  SimpleCov.start 'rails' do
    filters.clear
    add_filter do |src|
      src.filename !~ /^#{ENGINE_ROOT}/
    end
    add_filter '/spec/'
  end
  SimpleCov.command_name "spec"
end

require 'worthwhile'

Dir["./spec/support/**/*.rb"].sort.each {|f| require f}
require File.expand_path('../matchers', __FILE__)

FactoryGirl.definition_file_paths = [File.expand_path("../factories", __FILE__)]
FactoryGirl.find_definitions


RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.fixture_path = File.expand_path("../fixtures", __FILE__)

  config.before :each do
    if Capybara.current_driver == :rack_test
      DatabaseCleaner.strategy = :transaction
    else
      DatabaseCleaner.strategy = :truncation
    end
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.include Devise::TestHelpers, type: :controller
  config.include Devise::TestHelpers, type: :view
  config.include Warden::Test::Helpers, type: :feature
  config.after(:each, type: :feature) { Warden.test_reset! }
  config.include Controllers::EngineHelpers, type: :controller
  config.include Capybara::DSL
end
