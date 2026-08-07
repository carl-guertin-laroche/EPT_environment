# azr-chromeleon-devtests-london
variable "subscription_id" {
   default =   "7a9a1455-c13b-435f-ae84-6e464515eefa"
}

# azr-chromeleon-devtests-london
variable "tenant_id" {
   default =   "b67d722d-aa8a-4777-a169-ebeb7a6a3b67"
}

# use a region close to the training region
# change in terraform.tfvars
variable "region" {
  type    = string
}

# take care to give each resource group a differnt name
# change in terraform.tfvars
variable "rgname" {
  type    = string
}

# number of pods is usually the number of training participants + one for the trainer 
# change in terraform.tfvars
variable "numberofpods" {
  type    = number
}

# add your public IP address 
# change in terraform.tfvars 
# variable "friendlynetworks" {
#  type    = list(string)
#}

# vnet ip address
# change in terraform.tfvars
variable "vnetip" {
  type = number
}

# allowed TCP ports on the VMs
variable "friendlyports" {
  type    = string
}

# VM admin user name
# change in terraform.tfvars
variable "vmadmusername" {
  type    = string
}

# VM admin password
# change in terraform.tfvars
variable "vmadmpassword" {
  type    = string
}

variable "srv-vmsize" {
   type    = string
   default = "Standard_D4ads_v5"
}

variable "clt-vmsize" {
   type    = string
   default = "Standard_D4ads_v5"
}

# number of fileshares per pod
variable "numberoffileshare" {
   type    = number
   default = 0
}

# number of servers in a pod
# change in terraform.tfvars
variable "numberofserver" {
   type     = number
}

# number of Windows clients in a pod
# change in terraform.tfvars
variable "numberofw11clients" {
   type     = number
}

# number of shared servers (shared by all pods, e.g domain controler, file server)
# change in terraform.tfvars
variable "numberofsharedserver" {
  type    = number
  default =   0
}

variable "environment_type" {
  description = "Chromeleon deployment type"
  type        = string
  default     = "Training"

  validation {
    condition     = contains(["Training", "Validation", "Development"], var.environment_type)
    error_message = "environment_type must be Training, Validation, or Development."
  }
}

variable "timezone_id" {
  description = "Windows time zone for the VM"
  type        = string
  default     = "UTC"
}

variable "trendmicro_tenant_id" {
  type      = string
  sensitive = true
}

variable "trendmicro_token" {
  type      = string
  sensitive = true
}

variable "trendmicro_policy_id" {
  type = string
}

variable "default_tags" {
  type = map(string)
  default = {
    "app role"             = "CM Enterprise Training Playground"
    application            = "Chromeleon"
    "application owner"    = "eCDS Support Team"
    application_support    = "eCDS Support Team"
    costcenter             = "42000"
    department             = "eCDS Support"
    division               = "CMD"
    environment            = "Sandbox"
    finance_contact        = "Yuling.luo@thermofisher.com"
    group                  = "eCDS Support Team"
    infrastructure_support = "eCDS Support Team"
    operating_system       = "Windows"
  }


}