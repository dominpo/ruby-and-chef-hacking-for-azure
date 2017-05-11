
require 'chef/provisioning/azurerm'
with_driver 'AzureRM:67f8f17a-XXXX-XXXX-XXXX-b36b13bdfb0b'

azure_resource_group 'chefazure-pipeline-dev' do
  location 'North Europe'
end

azure_resource_template 'dev-env' do
  resource_group 'chefazure-pipeline-dev'
  template_source 'cookbooks\chefazure-pipeline\files\shared\machine_deploy.json'
  parameters location: 'North Europe',
             vmSize: 'Standard_D1',
             newStorageAccountName: 'chef-dev-env-stg',
             adminUsername: 'dominpo',
             adminPassword: 'P?asswor!d1',
             dnsNameForPublicIP: 'chefazure-dev',
             imagePublisher: 'Canonical',
             imageOffer: 'UbuntuServer',
             imageSKU: '14.04.3-LTS',
             vmName: 'dominpodev'
  chef_extension client_type: 'LinuxChefClient', version: '1210.12', runlist: 'role[devrole]'
end