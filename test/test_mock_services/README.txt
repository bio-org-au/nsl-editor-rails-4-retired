This directory holds the files necessary to run up a mock nsl-services server for testing the editor.

The mock server is a simple Sinatra app.

It currently supports the "make reference citation" service, but the plan is to support more.

Requirements

- currently uses ruby 2.2.1
- sinatra gem
- rerun gem

Configuration

You need to tell the Rails Editor where to find the services - the Rails editor will load the test config from ~/.nsl/test/editor-config.rb.

There is a sample editor-config.rb file in a tarzip file under config/.

Running it: use the shell script to run the server.



