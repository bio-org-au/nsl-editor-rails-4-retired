#! /bin/bash

# For this to work on a fresh install you need Java and NodeJS. How you install these is up to you, but on fedora linux
# I use sdkman (https://sdkman.io) to install java 'sdk install java 8.0.242.j9-adpt'
# and 'dnf install git nodejs'

mkdir -p vendor/bundle/
JRUBY_ZIP=bin/jruby-dist-9.1.12.0-bin.zip
JAVA_OPTS='-server -d64'
JRUBY_HOME=$PWD/bin/jruby-9.1.12.0

if [ ! -d "$JRUBY_HOME" ]; then
  if [ ! -f "$JRUBY_ZIP" ]; then
    curl https://repo1.maven.org/maven2/org/jruby/jruby-dist/9.1.12.0/jruby-dist-9.1.12.0-bin.zip --output $JRUBY_ZIP
  fi
  unzip -d bin $JRUBY_ZIP
fi

PATH=$JRUBY_HOME/bin:$PATH
EDITOR_CONFIG_FILE=editor-build-config.rb
EDITOR_CONFIGDB_FILE=editor-build-database.yml

export JAVA_OPTS JRUBY_HOME PATH EDITOR_CONFIG_FILE EDITOR_CONFIGDB_FILE

echo "** info"
echo PATH:- "$PATH"
echo "** JAVA VERSION"
command -v java
java -version
echo "** JRUBY VERSION"
command -v jruby
jruby -v
echo $JRUBY_HOME

echo "** remove existing war files"
rm ./*.war || echo "no war files"

echo "** gem install"
jruby -S gem install bundler -v 2.0.2
jruby -S bundle config set without 'development test'
jruby -S bundle install

echo "** compile assets"
jruby -S bundle exec rake assets:clobber
jruby -S bundle exec rake assets:precompile  RAILS_ENV=production RAILS_GROUPS=assets

echo "** create war"
jruby -S bundle exec warble
