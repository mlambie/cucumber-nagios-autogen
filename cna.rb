#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "slop"

opts = Slop.parse(:arguments => true) do
  banner "Usage: cna.rb -u <user> -h <host> -p <vhost_path> -t <target>"
  on :u, :user=, 'User', :default => ENV["USER"]
  on :h, :host=, 'Host', :default => "localhost"
  on :p, :path=, 'Vhost path', :default => "/etc/apache2/sites-available/"
  on :t, :target=, 'Target directory'
end

# we can't use a default :target in opts because we rely on opts[:host]
target = opts.target? ? opts[:target] : "./#{opts[:host]}/"

begin
  sites = `ssh #{opts[:user]}@#{opts[:host]} 'ls -1 #{opts[:path]}'`.split("\n").sort!
  sites.delete_if { |x| /^default/i.match x  }
  sites.each do |site|
    # puts site
  end
rescue Exception => e
  abort "Fatal! #{e}"
end