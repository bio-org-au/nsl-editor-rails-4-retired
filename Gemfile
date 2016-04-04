source "https://rubygems.org"

gem "rails", "~> 4.1.9"

platform :jruby do
  gem "activerecord-jdbcpostgresql-adapter"
end

platform :ruby do
  gem "pg"
end

gem "sass-rails", "~> 4.0.3"
gem "autoprefixer-rails"
gem "bootstrap-sass"
gem "uglifier", ">= 1.3.0"
gem "coffee-rails", "~> 4.0.0"
gem "therubyrhino"
gem "jquery-rails"
gem "jquery-ui-rails"
gem "turbolinks"
gem "jbuilder", "~> 2.0"
# bundle exec rake doc:rails generates the API under doc/api.
gem "sdoc", "~> 0.4.0", group: :doc
# warbler for rake tasks to generate a WAR file
gem "warbler"

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development do
  gem "puma"
  gem "awesome_print"
  gem "better_errors", "~>1.0"
  gem "spring"
  gem "binding_of_caller", platforms: [:mri_19, :mri_20, :mri_21, :rbx]
  gem "guard-bundler"
  gem "guard-rails"
  gem "guard-test"
  gem "quiet_assets"
  gem "rails_layout"
  gem "rb-fchange", require: false
  gem "rb-fsevent", require: false
  gem "rb-inotify", require: false
end

group :development, :test do
  gem "pry-rails"
  gem "pry-rescue"
  gem "schema_plus"
end

group :test do
  gem "capybara"
  gem "minitest"
  gem "minitest-rails"
  gem "minitest-capybara"
  gem "minitest-rails-capybara"
  gem "capybara_minitest_spec"
  gem "selenium-webdriver", "~> 2.45", require: false
  gem "launchy"
  gem "mocha", "~> 1.1.0"
end

platform :ruby do
  group :test do
    gem "capybara-webkit", require: false
  end
end

gem "kramdown"
gem "seed_dump"

# gem 'activejob', '~> 0'
gem "delayed_job_active_record"

gem "figaro"
gem "rest-client"

gem "active_type"
gem "net-ldap"

gem "strip_attributes"
gem "exception_notification"

gem "composite_primary_keys", "=7.0.13" # for Rails 4.1
gem "cancancan", "~> 1.10"

gem "sucker_punch", "~> 1.0"
gem "activejob_backport"
gem "underscore-rails"

gem "pg_search"
gem "acts_as_tree"
gem "font-awesome-rails"
