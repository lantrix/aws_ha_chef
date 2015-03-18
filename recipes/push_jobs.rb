#
# Cookbook Name:: aws_ha_chef
# Recipe:: push_jobs
#
# This recipe installs the push jobs add-on.

execute 'chef-server-ctl install opscode-push-jobs-server' do
  not_if "dpkg-query -W opscode-push-jobs-server"
end
