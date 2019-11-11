# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "4.2.7.1"

platform :jruby do
  gem "activerecord-jdbcpostgresql-adapter", "1.3.24", :platform => :jruby
  # warbler for rake tasks to generate a WAR file and use jruby 9.1.5.0
  gem "jruby-jars", "9.1.5.0"
  gem "warbler"
  gem 'json', '~> 1.8', '>= 1.8.6'
  gem "therubyrhino"
end

platform :ruby do
  gem 'pg', '~> 0.21'
end

platform :jruby do
  gem "sass-rails", "~> 4.0.3"
  gem "autoprefixer-rails", '8.6.5'
  gem "bootstrap-sass"
end
# gem "uglifier", ">= 1.3.0"
gem "coffee-rails", "~> 4.0.0"
gem "jquery-rails"
gem "jquery-ui-rails"
gem "turbolinks"
gem "jbuilder", "~> 2.0"
# bundle exec rake doc:rails generates the API under doc/api.
gem "sdoc", "~> 0.4.0", group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development do
  gem "puma"
  gem "better_errors", "~>1.0"
  gem "spring"
  gem "binding_of_caller", platforms: [:mri_19, :mri_20, :mri_21, :rbx]
  gem "quiet_assets"
  gem "rails_layout"
end

group :development, :test do
  gem "pry-rails"
  gem "pry-rescue"
  gem "webmock"
  # gem "schema_plus"
end

group :test do
    gem "minitest"
    gem "minitest-rails"
    gem "minitest-reporters"
    gem "launchy"
    gem "mocha", "~> 1.1.0"
end

gem "kramdown"
gem "seed_dump"

# gem 'activejob', '~> 0'
gem "delayed_job_active_record"

gem "figaro"
gem "rest-client"

gem "active_type"
gem "net-ldap", "~> 0.16.0"

gem "strip_attributes"
gem "exception_notification"

gem "composite_primary_keys"
gem "cancancan", "~> 1.10"

gem "sucker_punch", "~> 1.0"
gem "activejob_backport"
gem "underscore-rails"

gem "pg_search"
gem "acts_as_tree"

# Removed because it seems to stop icons Angular part of the app.
# Restored because getting rid of Angular.
gem "font-awesome-rails"
gem "comma", "~> 4.1" # csv dsl
gem "awesome_print"
