begin 
  Rails.configuration.version_file_name = 'version.properties'
  puts "Reading the app version from the #{Rails.configuration.version_file_name} file"
  version='unknown'
  a = File.readlines(Rails.configuration.version_file_name)
  a.select {|line| line =~ /appversion/}
  b = a.select {|line| line =~ /appversion/}
  version = b.first.chomp.split('=').last
  puts("Configuring version #{version} of the app.")
  Rails.configuration.version = version
rescue => e
  puts e.to_s
  puts "Warning: config couldn't find the app version from the expected file."
  puts "Action: check #{Rails.configuration.version_file_name} exists and has an 'appversion=...' line"
  Rails.configuration.version = 'unknown'
end
