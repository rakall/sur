locals {
  publisher                  = "checkpoint"
  sku                        = "sg-byol"
  nvasize                    = "Standard_D3_v2"
  nvaminnodes                = "2"
  nvamaxnodes                = "10"
  installationType           = "vmss"
  allowUploadDownload        = "true"
  useradmin                  = "notused"
  isBlink                    = "True"
  bootstrapScript64          = ""
  custom_data_loc            = "./modules/nva/config.sh"
  managementGUIClientNetwork = ""
  osVersion                  = "R8030"
  templateName               = "vmss-v2"
  templateVersion            = "20190814"
  product_purpose            = "ntfw"
  offer                      = "check-point-cg-r8030"
  ver                        = "latest"
  channel                    = "internet"
  description                = "HUB NVA"
  product                    = "HubNVA"
  cia                        = "AHC"
  nva_name                   = "${var.entity}${var.environment}${lookup(var.location_short, var.location)}vss${lookup(var.product_name_short, var.product_name)}gen${local.product_purpose}${lookup(var.nvaId, var.product_name)}"
  elb_name                   = "${var.entity}${var.environment}${lookup(var.location_short, var.location)}lba${lookup(var.product_name_short, var.product_name)}fro${local.product_purpose}${lookup(var.LBId, var.product_name)}"
  ilb_name                   = "${var.entity}${var.environment}${lookup(var.location_short, var.location)}lba${lookup(var.product_name_short, var.product_name)}bac${local.product_purpose}${lookup(var.LBId, var.product_name)}"
  configurationTemplate      = var.template_name
}

# Common variables
variable "location" {
  description = "Location to deploy"
}


variable "resource_group" {
  type        = string
  description = "Resource Group to deploy NVA"
}

variable "environment" {
  default     = "p1"
  type        = string
  description = "(Optional) the environment"
}

variable "entity" {
  type        = string
  description = "(Required) Entity"
}

variable "location_short" {
  type        = map
  description = "(Optional) Maps the location acronym with the location name."

  default = {
    brazilsouth = "zb1"
    eastus      = "zu1"
    eastus2     = "zu2"
    global      = "glb"
    northeurope = "neu"
    westeurope  = "weu"
    southuk     = "suk"
  }
}

variable "configurationTemplate" {
  type        = map
  description = "(Optional) Maps the product_name_short with the configurationTemplate."

  default = {
    NorthInternetCorporate     = "fwinet30"
    SouthProductionCorporate   = "fwpro30"
    SouthnoProductionCorporate = "fwnopro30"
  }
}

variable "nvaId" {
  type        = map
  description = "(Optional) Maps the product_name_short with the configurationTemplate."

  default = {
    NorthInternetCorporate     = "101"
    SouthProductionCorporate   = "202"
    SouthnoProductionCorporate = "303"
  }
}

variable "LBId" {
  type        = map
  description = "(Optional) Maps the product_name_short with the configurationTemplate."

  default = {
    NorthInternetCorporate     = "001"
    SouthProductionCorporate   = "002"
    SouthnoProductionCorporate = "003"
  }
}

variable "product_name" {
  type        = string
  description = "[NorthInternetCorporate, SouthProductionCorporate, SouthnoProductionCorporate]"
}


variable "product_name_short" {
  type        = map
  description = "(Optional) Maps the product_name_short with the configurationTemplate."

  default = {
    NorthInternetCorporate     = "nic"
    SouthProductionCorporate   = "spc"
    SouthnoProductionCorporate = "snc"
  }
}

# Virtual Network information

variable "vnet_name" {
  description = "Existing virtual network where to deploy the NVA"
}


variable "snt_front_name" {
  description = "Name of existing subnet to use as FRONT"
}

variable "snt_back_name" {
  description = "Name of existing subnet to use as BACK"
}


# Storage resources
variable "sa_name" {
  description = "Name for the storage account used to store boot diag scaleset"
}

# Variables for NVA configuration
variable "zones" {
  type        = list(number)
  description = "(Optional) A list of Availability Zones in which the Virtual Machines in this Scale Set should be created in. Eg. [1, 2, 3]"
  default     = []
}

variable "useradmin" {
  description = "Name for the admin user (notused currently)"
  default     = "notused"
}


variable "offer" {
  default = "check-point-cg-r8030"
}

variable "ver" {
  default = "latest"
}

variable "instances" {
  description = " The number of Virtual Machines in the Scale Set."
  default     = "2"
}

# Customdata configuration variables (CheckPoint configuration script)


# Tagging

variable "channel" {
  type        = string
  description = "(Optional) Distribution channel to which the associated resource belongs to."
  default     = "Internet"
}

variable "description" {
  type        = string
  description = "(Required) Provide additional context information describing the resource and its purpose."
  default     = "HubNVA"
}

variable "tracking_code" {
  type        = string
  description = "(Required) Allow this resource to be matched against internal inventory systems."
  default     = ""
}


variable "cia" {
  type        = string
  description = "(Required) Allows a  proper data classification to be attached to the resource."
  default     = "AHC"
}

variable "lwk_id" {
  type        = string
  description = "(Optional) The Id of the LWK."
}

variable "vnet_resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group the Virtual Network is located in."
}

variable "name_sicKeySecret" {
  type    = string
  default = "chkp-key"

}

variable "key_vault_id" {
}

variable "managementServer" {
}

variable "subscription_id" {
  type        = string
  description = "(Required) The Subscription ID"
}
variable "vmss_sku" {
  type        = string
  description = "(Required) The VM scale set SKU. Should be set to Standard_D3_v2"
  default     = "Standard_D3_v2"
}
variable "template_name" {
  type        = string
  description = "(Required) Configuration template name"
}
