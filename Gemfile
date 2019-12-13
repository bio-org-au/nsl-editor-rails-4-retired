source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.7'
# Use jdbcpostgresql as the database for Active Record
gem 'activerecord-jdbcpostgresql-adapter'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyrhino'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]


gem "jruby-jars", "9.2.5.0"
gem "warbler"
gem 'json', '~> 1.8', '>= 1.8.6'
gem "autoprefixer-rails"
#gem "bootstrap-sass"
#gem "jquery-rails"
#gem "jquery-ui-rails"


group :development do
  gem "better_errors", "~>1.0"
  gem "spring"
  gem "binding_of_caller", platforms: [:mri_19, :mri_20, :mri_21, :rbx]
  #gem "quiet_assets"
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
    #gem "minitest-rails"
    gem "minitest-reporters"
    gem "launchy"
    gem "mocha", "~> 1.1.0"
end

# gem "kramdown"
gem "seed_dump"

# gem 'activejob', '~> 0'
# gem "delayed_job_active_record"

gem "figaro"
gem "rest-client"

gem "active_type"
gem "net-ldap", "~> 0.16.0"

# gem "strip_attributes"
# gem "exception_notification"

# gem "composite_primary_keys"
gem "cancancan", "~> 1.10"

gem "sucker_punch", "~> 1.0"
gem "activejob_backport"
gem "underscore-rails"

# gem "pg_search"
# gem "acts_as_tree"

# Removed because it seems to stop icons Angular part of the app.
# Restored because getting rid of Angular.
gem "font-awesome-rails"
gem "comma", "~> 4.1" # csv dsl
gem "awesome_print"
