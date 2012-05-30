#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "slop"

opts = Slop.parse(:arguments => true) do
  banner "Usage: cna.rb -u <user> -h <host> -p <vhost_path> -t <target>"
  on :u, :user=, 'User', :default => ENV["USER"]
  on :h, :host=, 'Host', :default => "localhost"
  on :p, :path=, 'Vhost path', :default => "/etc/apache2/sites-available/"
  on :t, :target=, 'Target base directory'
  on :p, :project=, 'Project'
end

# We can't use a default :target in opts because we rely on opts[:host]
project = opts.project? ? opts[:project] : opts[:host]
target =  opts.target? ?  opts[:target]  : "/srv/cucumber-nagios/#{project}"

begin
  sites = `ssh #{opts[:user]}@#{opts[:host]} 'ls -1 #{opts[:path]}'`.split("\n").sort!
  sites.delete_if { |x| /^default/i.match x  }
  
  # Cucumber Nagios generation script
  cn_fname = "cucumber-nagios-#{project}.sh"
  # Nagios configuration file
  n_cmd_fname = "cucumber-nagios-commands-#{project}.cfg"
  n_svc_fname = "cucumber-nagios-services-#{project}.cfg"
  [cn_fname, n_cmd_fname, n_svc_fname].each { |file| raise "File #{file} exists!" if File.exists? file }
  cnf = File.open(cn_fname, "w")
  ncmdf = File.open(n_cmd_fname, "w")
  nsvcf = File.open(n_svc_fname, "w")
  
  begin
    cnf.write "#!/bin/bash\n"
    cnf.write "cucumber-nagios-gen project #{project}\n"
    cnf.write "cd #{target}\n"
    sites.each do |site|
      cnf.write "cucumber-nagios-gen feature #{site} homepage\n"
      
      ncmdf.write "define command { \n"
      ncmdf.write "  command_name  cn-#{site}-homepage\n"
      ncmdf.write "  command_line  cd #{target} && cucumber-nagios features/#{site}/homepage.feature\n"
      ncmdf.write "}\n\n"
      
      nsvcf.write "define service { \n"
      nsvcf.write "  use                  generic-service\n"
      nsvcf.write "  host_name            #{opts[:host]}\n"
      nsvcf.write "  service_description  Cucumber-Nagios #{site} home page\n"
      nsvcf.write "  check_command        cn-#{site}-homepage\n"
      nsvcf.write "}\n\n"
    end
  ensure
    [cnf, ncmdf, nsvcf].each { |file| file.close unless file.nil? }
  end
rescue Exception => e
  abort "ERROR: #{e}"
end