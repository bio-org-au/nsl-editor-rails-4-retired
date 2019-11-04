#! /bin/bash

JRUBY_ZIP=bin/jruby-dist-9.1.12.0-bin.zip
export JAVA_OPTS='-server -d64'
export JRUBY_HOME=./bin/jruby-9.1.12.0

if [ ! -d "$JRUBY_HOME" ]; then
  if [ ! -f "$JRUBY_ZIP" ]; then
    curl https://repo1.maven.org/maven2/org/jruby/jruby-dist/9.1.12.0/jruby-dist-9.1.12.0-bin.zip --output $JRUBY_ZIP
  fi
  unzip -d bin $JRUBY_ZIP
fi

export PATH=$JRUBY_HOME/bin:$PATH
export EDITOR_CONFIG_FILE=editor-build-config.rb
export EDITOR_CONFIGDB_FILE=editor-build-database.yml

echo "** info"
echo PATH:- $PATH
echo "** JAVA VERSION"
command -v java
java -version
echo "** JRUBY VERSION"
command -v jruby
jruby -v

echo "** remove existing war files"
rm ./*.war || echo "no war files"

echo "** gem install"
jruby bin/jruby-9.1.12.0/bin/gem install bundler
jruby bin/jruby-9.1.12.0/bin/bundle install --without development test

echo "** compile assets"
bundle exec rake assets:clobber
bundle exec rake assets:precompile  RAILS_ENV=production RAILS_GROUPS=assets

echo "** create war"
bundle exec warble
