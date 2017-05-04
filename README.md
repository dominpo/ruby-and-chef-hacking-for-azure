# Ruby and Chef Hacking for Microsoft Azure

In this hackfest repo, we are going to:

* Code in Ruby language to provision Azure resources using the [Ruby SDK for Azure](https://github.com/azure/azure-sdk-for-ruby)

* Automate the process with Chef using [Chef Provider for Azure](https://github.com/pendrica/chef-provisioning-azurerm)

* Setup full DevOps with Jenkins 


## Part 1 - Ruby code to provision your Azure Resources

### Environment settings
* Install the [Ruby and Ruby Development Kit](http://rubyinstaller.org/)
(for exemple on c:\ruby2.3.3)

* To code in ruby (and for chef cookbooks too), [Visual Studio Code](https://code.visualstudio.com/download) with Ruby extension (and Chef extension), available for Windows, Linux and Mac is a great tool. 
To install Ruby (and Chef) VS Code Extension, it [here](https://marketplace.visualstudio.com/VSCode)

Verify that Ruby is up and running !

```bash
>ruby --version
ruby 2.3.3p222 (2016-11-21 revision 56859) [i386-mingw32]
```
* Then install the [Azure SDK for Ruby (ARM mode)](https://github.com/azure/azure-sdk-for-ruby) with the following gem commands 

```bash
gem install azure_mgmt_compute
gem install azure_mgmt_storage
gem install azure_mgmt_resources
gem install azure_mgmt_network
```

and you're ready to go ! 

well, not exactly, in fact, like for a user to access Azure Ressources, an App need to have an identity (credential) allowed to access Azure Resources. This is done by creating a Service Principal in Azure Resource Manager mode.

### Create an authorized identity for your Ruby App (Azure Service Principal)

We are gonna used the new great [Azure CLI 2.O](https://docs.microsoft.com/en-us/cli/azure/overview) for that.
After you install it, you can begin to play with it :
```bash
> az
> az login
> az account list
> az account set --subscription "Azure_MySubscription"
> az account show 
```
here is the list of all commands to execute:  (for more [information](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?toc=%2fazure%2fazure-resource-manager%2ftoc.json)

```bash
>az account show
{
  "environmentName": "AzureCloud",
  "id": "e304f6cc-XXXX-XXXX-XXXX-7599c05fd6a9",
  "isDefault": true,
  "name": "Services de la plateforme Windows Azure pour Visual Studio Ultim",
  "state": "Enabled",
  "tenantId": "181de188-XXXX-XXXX-XXXX-d3598a78c31d",
  "user": {
    "name": "dominpo@hotmail.com",
    "type": "user"
  }
}

>az ad app create --display-name "my-ruby-app" --password "XXXXXXXXXX" --homepage "http://my-ruby-app" --identifier-uris "http://my-ruby-app/dominporubyapp"
{
  "appId": "7de03164-XXXX-XXXX-XXXX-212f454ab917",
  "appPermissions": null,
  "availableToOtherTenants": false,
  "displayName": "my-ruby-app",
  "homepage": "http://my-ruby-app",
  "identifierUris": [
    "http://my-ruby-app/dominporubyapp"
  ],
  "objectId": "b19d5772-XXXX-XXXX-XXXX-b9b251be1898",
  "objectType": "Application",
  "replyUrls": []
}

>az ad sp create-for-rbac --name 7de03164-XXXX-XXXX-a75b-212f454ab917 --password "XXXXXX"
{
  "appId": "837bf44e-XXXX-XXXX-XXXX-6c87cefd8361",
  "displayName": "7de03164-XXXX-XXXX-XXXX-212f454ab917",
  "name": "http://7de03164-XXXX-XXXX-XXXX-212f454ab917",
  "password": "XXXXXX",
  "tenant": "181de188-XXXX-XXXX-XXXX-d3598a78c31d"
}
```

To verify that the Service Principal has been created 
```bash
>az login --service-principal -u 837bf44e-XXXX-XXXX-XXXX-6c87cefd8361 --password XXXXXXXX --tenant 181de188-XXXX-XXXX-XXXX-d3598a78c31d
[
  {
    "cloudName": "AzureCloud",
    "id": "e304f6cc-XXXX-XXXX-XXXX-7599c05fd6a9",
    "isDefault": true,
    "name": "Services de la plateforme Windows Azure pour Visual Studio Ultim",
    "state": "Enabled",
    "tenantId": "181de188-XXXX-XXXX-XXXX-d3598a78c31d",
    "user": {
      "name": "837bf44e-XXXX-XXXX-XXXX-6c87cefd8361",
      "type": "servicePrincipal"
    }
  
]
```
Need to login again with a user which has required right to assign RBAC on the subscription
```bash
C:\Ruby2.3.3\samples>az login ```
```

and then affect Contributor right to the SP on this specific subscription
```bash
>az role assignment create --assignee 837bf44e-XXXX-XXXX-XXXX-6c87cefd8361 --role Contributor --scope "/subscriptions/e304f6cc-XXXX-XXXX-XXXX-7599c05fd6a9"
```

Using a text editor, open or create the file ~/.azure/credentials and add the following section:
```bash
[e304f6cc-XXXX-XXXX-XXXX-7599c05fd6a9]
tenant_id="181de188-XXXX-XXXX-XXXX-d3598a78c31d"
client_id="837bf44e-XXXX-XXXX-XXXX-6c87cefd8361"
client_secret="XXXXX"
```
Those 4 parameters will act as an identity to access and provision Azure Resources (with Ryby App and also later for Chef Cookbooks)


### Coding your Ruby App to provision Azure resources 

Again, if you need a great Ruby editing tool. Fee free to download [Visual Studio Code](https://code.visualstudio.com/download) and its [Ruby extension](https://marketplace.visualstudio.com/VSCode)

Download the ruby-app-azure.rb source code (ensure that you create file $home/.azure/credentials with your specific info)

and just run it !

```bash
>ruby ruby-app-azure.rb
```

The ruby app will ask you for some information like the Azure Region, Resource Group name, VNET name... 

If you encounter the issue "MissingSubscriptionRegistration" : "The subscription is not registered to use namespace 'Microsoft.Storage'...

You need to register your subscription with the different ARM providers :

```bash
>az provider show --namespace "Microsoft.Storage"
{
  "id": "/subscriptions/e304f6cc-XXXX-XXXX-XXXX-7599c05fd6a9/providers/Microsoft.Storage",
  "namespace": "Microsoft.Storage",
  "registrationState": "NotRegistered",
  ...
}

>az provider register --namespace "Microsoft.Storage"
Registering is still on-going. You can monitor using 'az provider show -n Microsoft.Storage'

>az provider show -n Microsoft.Storage
{
  "id": "/subscriptions/e304f6cc-XXXX-XXXX-XXXX-7599c05fd6a9/providers/Microsoft.Storage",
  "namespace": "Microsoft.Storage",
  "registrationState": "Registering",

```
and finally :
```bash
C:\Users\dominpo>az provider show --namespace "Microsoft.Storage"
{
  "id": "/subscriptions/e304f6cc-XXXX-XXXX-XXXX-7599c05fd6a9/providers/Microsoft.Storage",
  "namespace": "Microsoft.Storage",
  "registrationState": "Registered",
```
do the same for the differed used provider :
```bash
>az provider register --namespace "Microsoft.Network"
>az provider register --namespace "Microsoft.Compute"
```

for more information 
https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-common-deployment-errors#noregisteredproviderfound 

Instead of doing a step by step Azure resource deployment (which cause 1 ARM API call for each resource), you can do ARM template deployment in Ruby as describe [here](https://github.com/Azure-Samples/resource-manager-ruby-template-deployment)

You can also play with some other ruby samples by looking at some others Ruby code [here](https://azure.microsoft.com/fr-fr/resources/samples/?products=azure-resource-manager&platform=ruby)


## Part 2 - Automation Azure provisionning with Chef cookbook

This part is about the automation of the Azure provisioning with Chef using [Chef Provider for Azure](https://github.com/pendrica/chef-provisioning-azurerm)

Chef permit to do Infrastructure As Code with the notion of Cookbook, which is a collection of Recipes that contains a set of instructions to perform on Nodes (servers running Chef Client). Recipes are written in Chef domain-specific language (DSL) on top of Ruby. Nodes communicate with the Chef Server which is a repository for all cookbooks. 

for more information on Chef Architecture : https://docs.chef.io/chef_overview.html 

To develop and test Chef cookbook locally, you need to install the [ChefDK](https://downloads.chef.io/)

then you can generate a complete application using the Chef generate app command :

```bash
>chef generate app chefazure-test "Dominique Pochat" --email "dominpo@hotmail.com"
```
A new directory chefazure-test, files are created. A default recipe file is created chefazure-test/cookbooks/chefazure-test/recipes/default.rb

You can start a free trial of [Hosted Chef here](https://manage.chef.io/signup) and when done, create a new organization as a repository for your Azure Cookbook. You will then download the Starter Kit which contains required information for the Clients (nodes) to connect like a user private key, an organization validator key file, a knife configuration file.
Or you can also host your host server on Azure using the Market Place image : https://blog.chef.io/2015/03/30/chef-now-available-in-azure-marketplace/

Microsoft also worked with Chef to develop a Azure VM Extension (ChefClient for Windows and LinuxChefClient for Linux) which permit to automatically boostrap an Azure VM as a Chef Client (or node) : https://github.com/chef-partners/azure-chef-extension
It is possible to install it using the ARM Template, or using the portal or CLI for an existing VM.

```bash
>az vm extension image list --publisher "Chef.Bootstrap.WindowsAzure"
```

To add this VM extension to an ARM template :
```bash
...
chef_extension client_type: 'ChefClient',                               
  version: '1210.12'                               
  runlist: 'role[ webserver]'
...
```

Once you installed Chef Client on an Azure VM (using the portal or CLI), it will registered itself (with the private information you got from the Starter Kit) and you will see the VM in the Hosted Chef Management Portal on the Nodes Tab.

Like the Java App, you need an Azure Service Principal to call the ARM REST API. We can use the same one, we used with the Ruby App. Chef will get the information from our credentials file $home/.azure/credentials (just ensure that the file is there)



Chef Provisioning operates a driver model and there is one for Azure : https://github.com/chef/chef-provisioning
To install the Azure ARM provider for Chef, just run :

```bash
>chem gem install chef-provisioning-azurerm
```

The Chef Provisioning driver for Azure relies a lot of Ruby which communicate with the ARM API to create Azure Resource.

just modify the default.rb recipe file to create a Resource Group in your cookbook with the following (replace the Guid with your subscription id) :

```bash
require 'chef/ provisioning/ azurerm' 
with_driver 'AzureRM:e304f6cc-XXXX-XXXX-XXXX-7599c05fd6a9' 



azure_resource_group "chef-azure-RG" do     
 location 'North Europe'     
 tags CreatedFor: 'Using Chef to provision Azure Resource' 
end
```

then upload this cookbook (and default recipe) on the Chef server using Knife tool :
```bash
> knife cookbook upload provision
```

To test locally this default recipe with our workstation, just run chef-client. The workstation will appear on the Nodes in the Chef Management Portal :

and then run the default recipe :

```bash
> chef-client -o recipe[ provision:: default]
```

using Azure CLI, we can see that the Resource Group chef-azure-RG has been created :

```bash
> az group list 
```

While we can create all the Azure Resource with the Azure Chef Provider item like azure_resource_group, azure_storage_account, azure_network_interface, azure_public_ip_address...As mentioned [here](https://github.com/pendrica/chef-provisioning-azurerm), this will be deprecated by the azure_resource_template resource which described an ARM template file (json) which itself describe the complete topology of your Azure Infrastructure.
For more information about [Azure Resource Manager](https://docs.microsoft.com/en-us/azure/azure-resource-manager/)
You can get many ARM Template examples here on the [Azure Quickstart Template Github page](https://github.com/Azure/azure-quickstart-templates)

just pick one that match your need. Download the azuredeploy.json file that contains the ARM Template.
copy the file to cookbooks\provision\files\default\azuredeploy.json
and use the azure_resource_template in your recipe 

```bash
azure_resource_template "chef-deploy" do     
  resource_group "chef-ruby-azure"     
  template_source "cookbooks/provision/files/default/azuredeploy.json"     
 parameters     dnsLabelPrefix: 'chef-azure-book',                             
                vmName: 'chefrubyazurevm',                             
                adminUsername: 'azureadmin',                             
                adminPassword: 'XXXXXX',                             
                rdpPort: 3389 
 chef_extension client_type: 'ChefClient',  version: '1210.12'
end
```

upload the cookbook to your chef server and run it :

```bash
>knife cookbook upload provision
>chef-client -o recipe[provision::default]

```

More information on using Chef on Azure can be found [here](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/chef-automation)


## Part 3 - Full DevOps with Chef, Ruby, Git and Jenkins

Automation of the Azure Provisioning with Chef is Great ! We will now setup Continuous Integration pipeline.

We use the 2 Chef tools, which are deliver with the ChefDk, to do first check for ruby and cookbook syntax verification : 
[Rubocop](https://github.com/chef/cookstyle)
[Foodcritic]http://www.foodcritic.io/

and Cookbook Testing with [ChefSpec](https://docs.chef.io/chefspec.html) for Unit Testing and [Test Kitchen](http://kitchen.ci/) for Acceptance Testing.

Test Kitchen is written in Ruby, is distributed with the ChefDF and has plug-in architecture that allows to use it against popular cloud.
To install the Azure [ARM Driver for TestKitchen](https://github.com/pendrica/kitchen-azurerm) plugin, just run 

```bash
>chef gem install kitchen-azurerm
```

and we need to modify the Test Kitchen .kitchen.yml within the Chef Repo to use the AzureRM driver :

```bash
--- 
driver:     
  name: azurerm

driver_config:     
	subscription_id: '67f8f17a-XXXX-XXXX-XXXX-b36b13bdfb0b'     
	location: 'North Europe'     
	machine_size: 'Standard_DS1' 

provisioner:     
  name: chef_zero 

platforms:    
  - name: windows2012-r2         
   driver_config:             
   image_urn: Canonical:UbuntuServer: 14.04.3-LTS:latest         
  transport:             
   name: winrm 
   verifier:     
    name: inspec 

suites:    
 -name: default
 run_list:            
  - recipe[ chefazureprov:: default]         
  attributes:
```



