#
# Cookbook Name:: aws_ha_chef
# Recipe:: metal_destroy
#

# Destroys HA Chef 12 cluster in AWS.

require 'chef/provisioning/aws_driver'

# The developers have abandoned the fog driver, but not yet updated all the
# documentation. Don't fall in the tar pit like I did!
#with_driver 'fog:AWS'
with_driver 'aws'

# Destroy backends
machine 'backend1.example.local' do
  action :destroy
end
machine 'backend2.example.local' do
  action :destroy
end

# Destroy frontends
frontends = {
  'fe1' => { 'fqdn' => 'frontend1.example.local' },
  'fe2' => { 'fqdn' => 'frontend2.example.local' },
  'fe3' => { 'fqdn' => 'frontend3.example.local' }
}
frontends.each do |_host, host_data|
  machine host_data['fqdn'] do
    action :destroy
  end
end
