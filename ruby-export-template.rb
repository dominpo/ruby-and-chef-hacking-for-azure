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

def export_template()
  puts "Exporting the resource group template for #{$resourcegroupname}"
  export_result = $resource_client.resource_groups.export_template(
      $resourcegroupname,
      Azure::ARM::Resources::Models::ExportTemplateRequest.new.tap{ |req| req.resources = ['*'] }
  )
  puts export_result.template
  template_file = File.new("template.json",'w')
  template_file.puts(export_result.template)
  template_file.close
  puts ''
end

# main program 

# Get credentials
$credentials=getCredentials

# create azure main resources
$resource_client = Azure::ARM::Resources::ResourceManagementClient.new($credentials)
$resource_client.subscription_id = $subscription

print("\n")
print("What is the Resource Group name you want to get the Template file ...\n")
$resourcegroupname = gets().chomp

export_template()




