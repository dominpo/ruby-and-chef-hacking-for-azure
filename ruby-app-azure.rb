#
# Provisioning Azure Resources in Ruby
# Copyright:: 2017, Dominique Pochat, All Rights Reserved
#
require 'rubygems'
require 'fileutils'
require "net/http"
require "json"
require 'openssl'
require 'os'
# azure  rubygems
require 'azure_mgmt_storage'
require 'azure_mgmt_compute'
require 'azure_mgmt_resources'
require 'azure_mgmt_network'

# Need that if you run your Ruby App on Windows to avoid SSL_connect certificate verify failed (SSLError) 
if (OS.windows?) then 
                OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
end

# use to output 
def print_item(group)
  puts "\tName: #{group.name}"
  puts "\tId: #{group.id}"
  puts "\tLocation: #{group.location}"
  puts "\tTags: #{group.tags}"
  print_properties(group.properties)
end

def print_properties(props)
  puts "\tProperties:"
  props.instance_variables.sort.each do |ivar|
    str = ivar.to_s.gsub /^@/, ''
    if props.respond_to? str.to_sym
      puts "\t\t#{str}: #{props.send(str.to_sym)}"
    end
  end
  puts "\n\n"
end

def print_complexitem(resource)
  resource.instance_variables.sort.each do |ivar|
    str = ivar.to_s.gsub /^@/, ''
    if resource.respond_to? str.to_sym
      puts "\t\t#{str}: #{resource.send(str.to_sym)}"
    end
  end
  puts "\n\n"
end

# global variable to store Service Principal Credential of your Ruby App
$subscription= ""
$tenantId= ""
$clientId= ""
$clientSecret= ""

# Azure variables 
$region_dc = 'westus'
$resourcegroupname = 'ruby-resource-group'
$stgaccountname = 'rubystorageaccount'
$vnet_name = 'ruby-vnet'

$storage_account
$vnet


# function to get the Credentials from the file ~/.azure/credentials
def getCredentials(credsFile = "~/.azure/credentials")
    # Get the credentials in  file
    if (credsFile != "") 
    then
        puts ("Get credentials from file .azure/credentials to connect AZURE")
        puts ""
        credsFileFull=::File.expand_path(credsFile)
        raise "[ERROR] : No AZURE variables nor credentials file found" if not ::File.exist?(credsFileFull)
        ::File.open(credsFileFull) do |f|
        f.readlines.select { |line| line =~ /^(?!#).+/ }.each do |line|
            tokens = line.chomp.split('=', 2)
            if tokens[0] =~ /^\[[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\]$/
            then
               $subscription=tokens[0][1..-2]
               $tenantId=""
               $clientId=""
               $clientSecret=""
            end
            $tenantId=tokens[1].gsub!('"','') if tokens[0] =~ /^tenant_id\s*$/
            $clientId=tokens[1].gsub!('"','') if tokens[0] =~ /^client_id\s*$/
            $clientSecret=tokens[1].gsub!('"','') if tokens[0] =~ /^client_secret\s*$/
        end
    end
    else 
        raise "[ERROR] : No AZURE variables nor credentials file found"
    end
    raise "[ERROR] : Cannot get all needed credentials to login AZURE subscription" if $subscription == "" || $tenantId == "" || $clientId == "" || $clientSecret == ""

    puts "Your current Subscription: #{$subscription}"
    puts "Your current Tenant ID: #{$tenantId}"
    puts "Your current Client ID: #{$clientId}"
    puts "Your current Client password: #{$clientSecret}"

    # Get the credentials object 
    provider = MsRestAzure::ApplicationTokenProvider.new($tenantId,$clientId ,$clientSecret)
    credentials = MsRest::TokenCredentials.new(provider)
    return credentials
end

# function to create a Resource Group
def createResourceGroup(resource_group_name)
  resource_group_params = Azure::ARM::Resources::Models::ResourceGroup.new.tap do |rg|
   rg.location = $region_dc
  end
  puts 'Create Resource Group...'
  print_item $resource_client.resource_groups.create_or_update(resource_group_name, resource_group_params)
end

# function to create Storage account
def createStorageAccount(stg_account_name)
  puts "Creating a premium storage account named #{stg_account_name} in resource group #$resourcegroupname"
  storage_create_params = Azure::ARM::Storage::Models::StorageAccountCreateParameters.new.tap do |account|
    account.location = $region_dc
    account.sku = Azure::ARM::Storage::Models::Sku.new.tap do |sku|
      sku.name = Azure::ARM::Storage::Models::SkuName::PremiumLRS
      sku.tier = Azure::ARM::Storage::Models::SkuTier::Premium
    end
    account.kind = Azure::ARM::Storage::Models::Kind::Storage
    account.encryption = Azure::ARM::Storage::Models::Encryption.new.tap do |encrypt|
      encrypt.services = Azure::ARM::Storage::Models::EncryptionServices.new.tap do |services|
        services.blob = Azure::ARM::Storage::Models::EncryptionService.new.tap do |service|
          service.enabled = false
        end
      end
    end
  end
  print_complexitem $storage_account = $storage_client.storage_accounts.create($resourcegroupname, stg_account_name, storage_create_params)
end


# function to create VNET account
def createVNET(vnet_name)
  puts 'Creating a virtual network'
  vnet_create_params = Azure::ARM::Network::Models::VirtualNetwork.new.tap do |vnet|
    vnet.location = $region_dc
    vnet.address_space = Azure::ARM::Network::Models::AddressSpace.new.tap do |addr_space|
      addr_space.address_prefixes = ['10.0.0.0/16']
    end
    vnet.dhcp_options = Azure::ARM::Network::Models::DhcpOptions.new.tap do |dhcp|
      dhcp.dns_servers = ['8.8.8.8']
    end
    vnet.subnets = [
        Azure::ARM::Network::Models::Subnet.new.tap do |subnet|
          subnet.name = 'Subnet1'
          subnet.address_prefix = '10.0.0.0/24'
        end
    ]
  end
  print_complexitem $vnet = $network_client.virtual_networks.create_or_update($resourcegroupname, vnet_name, vnet_create_params)
end

# function to create a Virtual Machine

def createVirtualMachine(  vm_name, user_name, user_pwd, subnet)

  puts "Creating public ip for the VM #{vm_name}...\n"

  public_ip_params = Azure::ARM::Network::Models::PublicIPAddress.new.tap do |ip|
    ip.location = $region_dc
    ip.public_ipallocation_method = Azure::ARM::Network::Models::IPAllocationMethod::Dynamic
    ip.dns_settings = Azure::ARM::Network::Models::PublicIPAddressDnsSettings.new.tap do |dns|
      dns.domain_name_label = 'ruby-domain-name'
    end
  end
  print_complexitem public_ip = $network_client.public_ipaddresses.create_or_update($resourcegroupname, 'ruby-pubip', public_ip_params)

  puts "Creating network interface for the VM #{vm_name}...\n"

  print_complexitem nic = $network_client.network_interfaces.create_or_update(
      $resourcegroupname,
      "ruby-nic-#{vm_name}",
      Azure::ARM::Network::Models::NetworkInterface.new.tap do |interface|
        interface.location = $region_dc
        interface.ip_configurations = [
            Azure::ARM::Network::Models::NetworkInterfaceIPConfiguration.new.tap do |nic_conf|
              nic_conf.name = "ruby-nic-#{vm_name}"
              nic_conf.private_ipallocation_method = Azure::ARM::Network::Models::IPAllocationMethod::Dynamic
              nic_conf.subnet = subnet
              nic_conf.public_ipaddress = public_ip
            end
        ]
      end
  )



  puts 'Creating a Ubuntu virtual machine...'
  vm_create_params = Azure::ARM::Compute::Models::VirtualMachine.new.tap do |vm|
    vm.location = $region_dc
    vm.os_profile = Azure::ARM::Compute::Models::OSProfile.new.tap do |os_profile|
      os_profile.computer_name = vm_name
      os_profile.admin_username = user_name
      os_profile.admin_password = user_pwd
    end

    vm.storage_profile = Azure::ARM::Compute::Models::StorageProfile.new.tap do |store_profile|
      store_profile.image_reference = Azure::ARM::Compute::Models::ImageReference.new.tap do |ref|
        ref.publisher = 'canonical'
        ref.offer = 'UbuntuServer'
        ref.sku = '16.04.0-LTS'
        ref.version = 'latest'
      end
      store_profile.os_disk = Azure::ARM::Compute::Models::OSDisk.new.tap do |os_disk|
        os_disk.name = "os-disk-#{vm_name}"
        os_disk.caching = Azure::ARM::Compute::Models::CachingTypes::None
        os_disk.create_option = Azure::ARM::Compute::Models::DiskCreateOptionTypes::FromImage
        os_disk.vhd = Azure::ARM::Compute::Models::VirtualHardDisk.new.tap do |vhd|
          vhd.uri = "https://#{$storage_account.name}.blob.core.windows.net/rubycontainer/#{vm_name}.vhd"
        end
      end    
    end

    vm.hardware_profile = Azure::ARM::Compute::Models::HardwareProfile.new.tap do |hardware|
      hardware.vm_size = Azure::ARM::Compute::Models::VirtualMachineSizeTypes::StandardDS2V2
    end

    vm.network_profile = Azure::ARM::Compute::Models::NetworkProfile.new.tap do |net_profile|
      net_profile.network_interfaces = [
          Azure::ARM::Compute::Models::NetworkInterfaceReference.new.tap do |ref|
            ref.id = nic.id
            ref.primary = true
          end
      ]
    end
   end 
    print_complexitem vm = $compute_client.virtual_machines.create_or_update($resourcegroupname, "ruby-vm-#{vm_name}", vm_create_params)
    vm
end


# main program 

# Get credentials
$credentials=getCredentials

# create azure main resources
$resource_client = Azure::ARM::Resources::ResourceManagementClient.new($credentials)
$resource_client.subscription_id = $subscription
$network_client = Azure::ARM::Network::NetworkManagementClient.new($credentials)
$network_client.subscription_id = $subscription
$storage_client = Azure::ARM::Storage::StorageManagementClient.new($credentials)
$storage_client.subscription_id = $subscription
$compute_client = Azure::ARM::Compute::ComputeManagementClient.new($credentials)
$compute_client.subscription_id = $subscription

print("\n")
print("Choose the DC you want to create your Azure resource\n")
print("1-West US \n")
print("2-North Europe\n")
print("?")

dc = gets().to_s.chomp
if (dc == '1')  then $region_dc = 'westus'
elsif (dc == '2')  then $region_dc = 'northeurope'
elsif puts("Enter 1 or 2")
end
print("Region will be #$region_dc...\n")

print("\n")
print("We need to create an Azure Resource Group (RG) where we will provision your Azure resources...\n")
print("Give a name for your RG?\n")
$resourcegroupname = gets().chomp
print("Your Azure resources will be create in #$resourcegroupname \n")
createResourceGroup($resourcegroupname)


print("\n")
print("We will create a storage account, a vnet, a public ip and Ubuntu VM in the Resource Group...\n")
print("Give a name for your storage account?\n")
$stgaccountname = gets().chomp
createStorageAccount($stgaccountname) 

print("\n")
print("We will now create a a vnet and default subnet to host the VM, give a name for your vnet?\n")
$vnet_name = gets().chomp
createVNET($vnet_name)

print("\n")
print("We will now create an Ubuntu VM, give a name for the VM...\n")
$vm_name = gets().chomp
print("admin name?\n")
$admin_name = gets().chomp
print("password ?\n")
$admin_pwd = gets().chomp
vm = createVirtualMachine( $vm_name, $admin_name, $admin_pwd, $vnet.subnets[0])


puts "List all of the resources within the group #$resourcegroupname \n"
$resource_client.resource_groups.list_resources($resourcegroupname).each do |res|
  print_complexitem res
end 