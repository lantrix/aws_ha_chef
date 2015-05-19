#
# Cookbook Name:: aws_ha_chef
# Recipe:: floating_ip
#

# Configures a secondary IP address on the primary back end server

# Required to build the cantakerous nokogiri gem
package 'gcc' do
  action :install
  provider Chef::Provider::Package::Apt
end.run_action(:install)

package 'libxml2-dev' do
  action :install
  provider Chef::Provider::Package::Apt
end.run_action(:install)

package 'libxslt-dev' do
  action :install
  provider Chef::Provider::Package::Apt
end.run_action(:install)

package 'libghc-zlib-dev' do
  action :install
  provider Chef::Provider::Package::Apt
end.run_action(:install)

package 'build-essential' do
  action :install
  provider Chef::Provider::Package::Apt
end.run_action(:install)

# Behold the Nokogiri and tremble in fear!
chef_gem 'nokogiri' do
  version '1.6.1'
  options "-- --use-system-libraries"
  action :install
end

# Now that the yak is properly shaved, we can install fog.
chef_gem 'fog'
require 'fog'

# Need a ~/.fog config file for the rest of this to work.
template "/root/.fog" do
  action :create
  owner "root"
  group "root"
  mode "0644"
  source "fog.erb"
end.run_action(:create)

# Fetch our MAC address
mac = File.read('/sys/class/net/eth0/address').strip
# Use the MAC to get our AWS interface ID
#eth0_interface_id = `curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/#{mac}/interface-id`
eth0_interface_id = Mixlib::ShellOut.new("curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/#{mac}/interface-id").run_command.stdout

log "print_network_info" do
  message "My MAC address is #{mac}\nMy interface id is #{eth0_interface_id}"
  level :debug
end.run_action(:write)

# Create a new AWS compute connection
connection = Fog::Compute.new(
  :provider               => :aws,
  :aws_access_key_id      => node['aws_ha_chef']['aws_access_key_id'],
  :aws_secret_access_key  => node['aws_ha_chef']['aws_secret_access_key'],
  :region                 => node['aws_ha_chef']['region'],
  :endpoint               => "https://ec2.#{node['aws_ha_chef']['region']}.amazonaws.com/"
)

# Here's where we attach the IP address
connection.assign_private_ip_addresses(eth0_interface_id, 'PrivateIpAddresses' => node['aws_ha_chef']['backend_vip']['ip_address'], 'AllowReassignment' => true )
