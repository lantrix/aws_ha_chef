#
# Cookbook Name:: aws_ha_chef
# Recipe:: hosts
#
# This recipe configures /etc/hosts so you can do local testing with 'fake'
# hostnames that are not in DNS.

# Fix the /etc/hosts file with the addresses of the front and back-end machines
# Run this during compile phase, we need these entries later in the recipe.
template '/etc/hosts' do
  action :create
  source 'hosts.erb'
  owner 'root'
  group 'root'
  mode '0644'
end.run_action(:create)

# Get our own hostname from the EC2 metadata API
#local_ipv4 = `curl -s http://169.254.169.254/latest/meta-data/local-ipv4`
local_ipv4 = Mixlib::ShellOut.new("curl -s http://169.254.169.254/latest/meta-data/local-ipv4").run_command.stdout

# Figure out who I am, based on the hosts file
node.default['set_fqdn'] = Mixlib::ShellOut.new("grep #{local_ipv4} /etc/hosts | awk '{ print $2 }'").run_command.stdout
include_recipe "hostnames::default"
