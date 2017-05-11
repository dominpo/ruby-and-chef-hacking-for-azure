
require 'chef/provisioning/azurerm'
with_driver 'AzureRM:67f8f17a-XXXX-XXXX-XXXX-b36b13bdfb0b'

azure_resource_group 'chefazure-pipeline-jenkins' do
  location 'North Europe'
end

azure_resource_template 'jenkins-server' do
  resource_group 'chefazure-pipeline-jenkins'
  template_source 'cookbooks\chefazure-pipeline\files\shared\machine_deploy.json'
  parameters location: 'North Europe',
             vmSize: 'Standard_D1',
             newStorageAccountName: 'chefdominpostg',
             adminUsername: 'dominpo',
             adminPassword: 'XXXXXXXX',
             dnsNameForPublicIP: 'chefazure-pipeline',
             imagePublisher: 'Canonical',
             imageOffer: 'UbuntuServer',
             imageSKU: '14.04.3-LTS',
             vmName: 'dominpojenkins'
  chef_extension client_type: 'LinuxChefClient', version: '1210.12', runlist: 'role[jenkins]'
end
