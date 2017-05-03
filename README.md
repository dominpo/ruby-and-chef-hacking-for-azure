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

The ruby program ask you for an Azure Region and Azure Resource Group where it need to create the Azure resource.

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

>az provider register --namespace "Microsoft.Network"
>az provider register --namespace "Microsoft.Compute"

for more information 
https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-common-deployment-errors#noregisteredproviderfound 




## Part 2 - Automation Azure provisionning with Chef cookbook





## Part 3 - Full DevOps with Chef, Ruby, Git and Jenkins
