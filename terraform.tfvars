# should not be changed
region = "eastus"

# Name of the resource group,e.g "rg-username0x" 
rgname = "rg-amer02"

# Ports used by pods only (inbound), no need to change this
friendlyports = "3389"

# Number of the second octet in the IP address of the pods
# Must be changed for every new terraform instance!
vnetip             = 70
vmadmusername      = "tadmin"              # Admin account user name
vmadmpassword      = "N0needtocompromise!" # Admin account password
numberofpods       = 1                     # Number of Pods (per user environment) = number of subnets = number of participants + trainers + spare
numberofserver     = 4                     # Number of servers per pod
numberofw11clients = 4                     # Number of Windows 11 clients per pod
environment_type      = "Training"
timezone_id           = "UTC"

trendmicro_tenant_id  = "7393525A-F236-C129-2E9C-DA34470C8DD7"
trendmicro_token      = "A8A8F9B3-71B0-0680-5B2C-97B3CDF85627"
trendmicro_policy_id  = "3829"