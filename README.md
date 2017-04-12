# Ruby and Chef Hacking for Windows Azure

In this hackfest repo, we are going to:

* Code in Ruby language to provision Azure resources using the [Ruby SDK for Azure](https://github.com/azure/azure-sdk-for-ruby)

* Automate the process with Chef using [Chef Provider for Azure](https://github.com/pendrica/chef-provisioning-azurerm)

* Setup full DevOps with Jenkins 


## Part 1 - Ruby code to provision your Azure Resources

### Environment settings
* Install the [Ruby and Ruby Development Kit](http://rubyinstaller.org/)
(for exemple on c:\ruby2.3.3)

* To code in ruby (and for chef cookbooks too), [Visual Studio Code](https://code.visualstudio.com/download) with Ruby extension (and Chef extension) is a great tool. 
To install Ruby (and Chef) VS Code Extension, it [here](https://marketplace.visualstudio.com/VSCode)

Verify that Ruby is up and running !
>ruby --version
ruby 2.3.3p222 (2016-11-21 revision 56859) [i386-mingw32]

* Then install the [Azure SDK for Ruby (ARM mode)](https://github.com/azure/azure-sdk-for-ruby) with the following gem commands 

```bash
gem install azure_mgmt_compute
gem install azure_mgmt_storage
gem install azure_mgmt_resources
gem install azure_mgmt_network
```

and you're ready to go ! 

well, not exactly, in fact, like for a user to access Azure Ressources, an App need to have an identity (credential) allowed to access Azure Resources. This is done by creating a Service Principal in Azure Resource Manager mode.

### Create an authorized identity for your Ruby App (Service Principal)




## Part 2 - Automation Azure provisionning with Chef cookbook



## Part 3 - Full DevOps with Chef, Ruby, Git and Jenkins
