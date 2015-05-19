#
# Cookbook Name:: aws_ha_chef
# Recipe:: primary
#
# Copyright 2014, Chef
#
# All rights reserved - Do Not Redistribute
#

include_recipe "aws_ha_chef::hosts"
include_recipe "aws_ha_chef::disable_iptables"
include_recipe "aws_ha_chef::floating_ip"
include_recipe "aws_ha_chef::server"
include_recipe "aws_ha_chef::ha"
include_recipe "aws_ha_chef::ebs_volume"
include_recipe "aws_ha_chef::configfile"

# Create missing keepalived cluster status files
directory '/var/opt/opscode/keepalived' do
  action :create
  owner 'root'
  group 'root'
  mode '0755'
end

file '/var/opt/opscode/keepalived/current_cluster_status' do
  action :create
  content 'master'
  owner 'root'
  group 'root'
  mode '0644'
end

file '/var/opt/opscode/keepalived/requested_cluster_status' do
  action :create
  content 'master'
  owner 'root'
  group 'root'
  mode '0644'
end

# Must be run before attempting to install reporting
execute "chef-server-ctl reconfigure"
execute "chef-server-ctl start" do
  action :run
  retries 3
  retry_delay 30
end

# Make sure we have installed the push jobs and reporting add-ons
include_recipe 'aws_ha_chef::reporting'
include_recipe 'aws_ha_chef::push_jobs'

# Configure for reporting and push jobs

# looks like this also tries to use chef-zero, causing breakage when you run it via provisioning.
execute 'opscode-reporting-ctl reconfigure'
execute 'opscode-push-jobs-server-ctl reconfigure'

# Yo dawg, I heard you like to configure Chef Server
# We put a reconfigure command in your configuration recipe
# So you can configure while you configure
execute "chef-server-ctl reconfigure"

# Start up Chef server on the primary
# At this point we don't want to restart or reconfigure it again
# Fsck the secondary server, it's jealous of my EBS volume
execute "chef-server-ctl restart" do
  action :run
  retries 3
  retry_delay 30
end

# At this point we should have a working primary backend.  Let's pack up all
# the configs and make them available to the other machines.
execute "tar -czvf #{Chef::Config[:file_cache_path]}/core_bundle.tar.gz /etc/opscode" do
  action :run
  not_if { File.exist?("#{Chef::Config[:file_cache_path]}/core_bundle.tar.gz") }
end

execute "tar -czvf #{Chef::Config[:file_cache_path]}/reporting_bundle.tar.gz /etc/opscode-reporting" do
  action :run
  not_if { File.exist?("#{Chef::Config[:file_cache_path]}/reporting_bundle.tar.gz") }
end

# Now we have to have a way to serve it to the other machines.
# We'l spin up a lightweight Ruby webserver for this purpose.
template '/etc/init.d/ruby_webserver' do
  action :create
  owner 'root'
  group 'root'
  mode '0755'
  source 'ruby_webserver.erb'
end

# Start up the web server on port 31337
service 'ruby_webserver' do
  action :start
  supports :status => true
end
