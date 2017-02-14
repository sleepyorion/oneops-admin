#
# shared fog provider setup
#

require 'fog'


#
# compute provider
#

provider_class = ""
cloud_name = node[:workorder][:cloud][:ciName]
if node.workorder.services.has_key?("compute")
  cloud = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
  provider_class = node[:workorder][:services][:compute][cloud_name][:ciClassName].split(".").last.downcase
  provider_class = "openstack" if provider_class == "oneops"
  Chef::Log.info("provider: "+provider_class)
  node.set["provider_class"] = provider_class
end


case provider_class
when /ec2/

  provider = Fog::Compute.new({
    :provider => 'AWS',
    :region => cloud[:region],
    :aws_access_key_id => cloud[:key],
    :aws_secret_access_key => cloud[:secret]
  })

when /ibm/

  provider = Fog::Compute.new({
    :provider => 'IBM',
    :ibm_username => cloud[:ibm_username],
    :ibm_password => cloud[:ibm_password]
  })
  node.set[:storage_provider] = Fog::Storage.new({
    :provider => 'IBM',
    :ibm_username => cloud[:ibm_username],
    :ibm_password => cloud[:ibm_password]
  })

when /openstack/

  provider = Fog::Compute.new({
    :provider => 'OpenStack',
    :openstack_api_key => cloud[:password],
    :openstack_username => cloud[:username],
    :openstack_tenant => cloud[:tenant],
    :openstack_auth_url => cloud[:endpoint]
  })
    
when /rackspace/

  provider = Fog::Compute::RackspaceV2.new({
    :rackspace_api_key => cloud[:password],
    :rackspace_username => cloud[:username],
    :rackspace_region => cloud[:region]
  })

  network_provider = Fog::Rackspace::NetworkingV2.new({
    :rackspace_api_key => cloud[:password],
    :rackspace_username => cloud[:username],
    :rackspace_region => cloud[:region]
  })
  node.set["network_provider"] = network_provider

when /softlayer/
  require 'fog/softlayer'
  provider = Fog::Compute.new({
    :provider => 'softlayer',
    :softlayer_username => cloud[:username],
    :softlayer_api_key => cloud[:apikey]
  })
  
when /aliyun/
  require 'fog/aliyun'
  provider = Fog::Compute.new({
    :provider => 'aliyun',
    :aliyun_region_id => cloud[:region],
    :aliyun_zone_id => '', # "aliyun_zone_id" is not a required parameter
    :aliyun_url => cloud[:url],
    :aliyun_accesskey_id => cloud[:key],
    :aliyun_accesskey_secret => cloud[:secret]
  })

when /azure/
  provider = 'azure'

when /docker/
  provider = 'docker'

when /vagrant/
  provider = 'vagrant'

when /virtualbox/
  provider = 'virtualbox'

when /vsphere/
  provider = Fog::Compute.new(:provider => 'vsphere',
   :vsphere_server => cloud[:endpoint],
   :vsphere_username => cloud[:username],
   :vsphere_password=> cloud[:password],
   :vsphere_expected_pubkey_hash => cloud[:vsphere_pubkey])
end

#
#  block storage provider
#
storage_class = ""
if node.workorder.services.has_key?("storage")
  storage_service = node[:workorder][:services][:storage][cloud_name]
  storage = storage_service["ciAttributes"]
  storage_class = storage_service["ciClassName"].split(".").last.downcase
  node.set["storage_provider_class"] = storage_class
end

case storage_class
when /cinder/
    node.set["storage_provider"] = Fog::Volume.new({ 
      :provider => 'OpenStack',
      :openstack_api_key => storage[:password],
      :openstack_username => storage[:username],
      :openstack_tenant => storage[:tenant],
      :openstack_auth_url => storage[:endpoint]
    })  
when /rackspace/
  node.set[:storage_provider] = Fog::Rackspace::BlockStorage.new({
    :rackspace_api_key => cloud[:password],
    :rackspace_username => cloud[:username],
    :rackspace_region => cloud[:region]
  }) 
when /azure/
  provider_class = "azuredatadisk" 
end


if !node.has_key?(:storage_provider) || node.storage_provider == nil
     node.set[:storage_provider] = provider
     node.set[:storage_provider_class] = provider_class
end

node.set[:iaas_provider] = provider
