#
# Cookbook Name:: aws_ha_chef
# Recipe:: configure_ebs_volume
#

# This recipe will *not* work with the Chef 12 client, due to an issue with
# the LVM cookbook:  https://www.chef.io/blog/page/2/
# Use the Chef 11.16.4 client instead to bootstrap your chef servers.

# We have to run most of these during the compile phase, to make sure the
# EBS volume is created and properly mounted before the execute phase.

# Where mah gems at?
gems = { "di-ruby-lvm-attrib" => "0.0.16", "open4" => "1.3.4", "di-ruby-lvm" => "0.1.3", "chef-provisioning" => "1.0.1", "chef-provisioning-aws" => "1.0.4" }
gems.each do |gem, _version|
  gem_package gem do
    gem_binary('/opt/chef/embedded/bin/gem')
    action :install
    # in case you want to store them locally
    # source "#{Chef::Config[:file_cache_path]}/#{gem}-#{version}.gem"
  end.run_action(:install)
end

# It will always be Chef Metal to me. \m/
require 'chef/provisioning/aws_driver'
with_driver 'aws::us-west-2'
include_recipe 'lvm::default'

# Create an ~/.aws directory
directory "/root/.aws" do
  action :create
  owner "root"
  group "root"
  mode "0755"
end.run_action(:create)

# Create an .aws/config file
template "/root/.aws/config" do
  action :create
  owner "root"
  group "root"
  mode "0644"
  source "config.erb"
end.run_action(:create)

package 'lvm2' do
  action :install
end.run_action(:install)

chef_gem 'di-ruby-lvm' do
  action :install
end.run_action(:install)

# This no longer uses the aws cookbook. Instead we're using the Chef
# provisioning driver.
e = aws_ebs_volume 'chef_ebs_volume' do
  size 100
  device "/dev/xvdj"
  volume_type "io1"
  machine 'backend1.example.local'
  iops 3000
  availability_zone node['aws_ha_chef']['availability_zone']
  action :create
end

e.run_action(:create)
Chef::Log.debug("Volume ID is: #{Chef::Resource::AwsEbsVolume.get_aws_object_id('chef_ebs_volume', resource: e)}")
node.run_state['ebs_volume_id'] = Chef::Resource::AwsEbsVolume.get_aws_object_id('chef_ebs_volume', resource: e)

lvm_volume_group 'chef' do
  physical_volumes ['/dev/xvdj']

  logical_volume 'data' do
    size        '85%VG'
    filesystem  'ext4'
    mount_point '/var/opt/opscode/drbd/data'
  end

  only_if "fdisk -l /dev/xvdj | grep xvdj"
  retries 5
  retry_delay 30
end.run_action(:create)
