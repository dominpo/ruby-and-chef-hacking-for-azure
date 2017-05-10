
require 'chef/provisioning/azurerm'
with_driver 'AzureRM:67f8f17a-7aee-47a1-9033-b36b13bdfb0b'

azure_resource_group 'chefazure-pipeline' do
  location 'North Europe'
end

azure_resource_template 'jenkins-server' do
  resource_group 'chefazure-pipeline'
  template_source 'C:\Users\dominpo\chef\chefazure-pipeline\cookbooks\chefazure-pipeline\files\shared\machine_deploy.json'
  parameters location: 'North Europe',
             vmSize: 'Standard_D1',
             newStorageAccountName: 'chefdominpostg',
             adminUsername: 'dominpo',
             adminPassword: 'P?asswor!d1',
             dnsNameForPublicIP: 'chefazure-pipeline',
             imagePublisher: 'Canonical',
             imageOffer: 'UbuntuServer',
             imageSKU: '14.04.3-LTS',
             vmName: 'dominpojenkins'
  chef_extension client_type: 'LinuxChefClient', version: '1210.12', runlist: 'role[jenkins]'
end