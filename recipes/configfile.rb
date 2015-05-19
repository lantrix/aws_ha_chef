#
# Cookbook Name:: aws_ha_chef
# Recipe:: configfile
#

# Make sure /etc/opscode exists
directory '/etc/opscode' do
  action :create
  owner 'root'
  group 'root'
  mode '0644'
end

# Render the chef-server.rb config file
template '/etc/opscode/chef-server.rb' do
  action :create
  source 'chef-server.erb'
  owner 'root'
  group 'root'
  variables(
    lazy do
      {:ebs_volume_id => node.run_state['ebs_volume_id']}
    end
  )
  mode '0644'
end
