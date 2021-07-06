// Creationg and configuration of the External Load Balancer / Front Subnet
//
//--------------------------------------------------------------------------

#"Public ip address" External load balancer/frontend


data "azurerm_resource_group" "rsg" {
  name = var.resource_group
}

data "azurerm_log_analytics_workspace" "lag" {
  name                = "lwkspc"
  resource_group_name = "lwkspc"
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name
}

data "azurerm_subnet" "snt_front_name" {
  name                 = var.snt_front_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name
}

data "azurerm_subnet" "snt_back_name" {
  name                 = var.snt_back_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name

}

data "azurerm_key_vault_secret" "sicKeySecret" {
  name         = var.name_sicKeySecret
  key_vault_id = var.key_vault_id
}

resource "azurerm_public_ip_prefix" "public_ip_prefix" {
  name                = "${local.elb_name}-ppp01"
  location            = var.location
  resource_group_name = var.resource_group
  prefix_length       = 28
}

data "azurerm_public_ip_prefix" "data_pip_prefix" {
  name                = "${local.elb_name}-ppp01"
  resource_group_name = var.resource_group
  depends_on          = [azurerm_public_ip_prefix.public_ip_prefix]
}

resource "azurerm_public_ip" "pip" {
  name                = "${local.elb_name}-pip01"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Static"
  public_ip_prefix_id = azurerm_public_ip_prefix.public_ip_prefix.id
  sku                 = "Standard"
  depends_on = [data.azurerm_public_ip_prefix.data_pip_prefix]
}

#elb/  External load balanced frontend

resource "azurerm_lb" "elb" {
  name                = local.elb_name
  resource_group_name = var.resource_group
  location            = var.location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "frontname-${local.elb_name}"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
  depends_on = [azurerm_public_ip.pip]
}

resource "azurerm_lb_probe" "elb_probe" {
  name                = "probe-${local.elb_name}"
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.elb.id
  protocol            = "Tcp"
  port                = "8117"
  interval_in_seconds = "5"
  number_of_probes    = "2"
  depends_on          = [azurerm_lb.elb]
}

resource "azurerm_lb_rule" "elb_rule" {
  name                           = "${local.elb_name}-pip01"
  resource_group_name            = var.resource_group
  loadbalancer_id                = azurerm_lb.elb.id
  frontend_ip_configuration_name = "frontname-${local.elb_name}"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 8081
  backend_address_pool_id        = azurerm_lb_backend_address_pool.elb_pool.id
  probe_id                       = azurerm_lb_probe.elb_probe.id
  load_distribution              = "Default"
  depends_on                     = [azurerm_lb_probe.elb_probe, azurerm_lb_backend_address_pool.elb_pool]
}

resource "azurerm_lb_backend_address_pool" "elb_pool" {
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.elb.id
  name                = "Backpool-${local.elb_name}"
  depends_on          = [azurerm_lb.elb]
}

resource "azurerm_monitor_diagnostic_setting" "elb_dgm" {
  name                       = "${local.elb_name}-dgm"
  target_resource_id         = azurerm_lb.elb.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.lag.id

  log {
    category = "LoadBalancerAlertEvent"
    enabled  = true

    retention_policy {
      enabled = true
      days    = "30"
    }
  }

  log {
    category = "LoadBalancerProbeHealthStatus"
    enabled  = true

    retention_policy {
      enabled = true
      days    = "30"
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = "30"
    }
  }
  depends_on = [azurerm_lb.elb]
}

// Creationg and configuration of the Internal Load Balancer / Back Subnet
//
//--------------------------------------------------------------------------

# ilb/ backend

resource "azurerm_lb" "ilb" {
  name                = local.ilb_name
  resource_group_name = var.resource_group
  location            = var.location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                          = "frontname-${local.ilb_name}"
    subnet_id                     = data.azurerm_subnet.snt_back_name.id
    private_ip_address            = cidrhost(data.azurerm_subnet.snt_back_name.address_prefix, 6)
    private_ip_address_allocation = "static"
  }
}

resource "azurerm_lb_probe" "ilb_Probe" {
  name                = "probe-${local.ilb_name}"
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.ilb.id
  port                = "8117"
  protocol            = "tcp"
  interval_in_seconds = "5"
  number_of_probes    = "2"
  depends_on          = [azurerm_lb.ilb]
}

resource "azurerm_lb_backend_address_pool" "ilb_pool" {
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.ilb.id
  name                = "backpool-${local.ilb_name}"
  depends_on          = [azurerm_lb.ilb]
}

resource "azurerm_lb_rule" "ilb_rule" {
  name                           = "rule-${local.ilb_name}"
  resource_group_name            = var.resource_group
  loadbalancer_id                = azurerm_lb.ilb.id
  frontend_ip_configuration_name = "frontname-${local.ilb_name}"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  backend_address_pool_id        = azurerm_lb_backend_address_pool.ilb_pool.id
  probe_id                       = azurerm_lb_probe.ilb_Probe.id
  load_distribution              = "Default"
  depends_on                     = [azurerm_lb.ilb, azurerm_lb_backend_address_pool.ilb_pool]
}

resource "azurerm_monitor_diagnostic_setting" "ilb_dgm" {
  name                       = "${local.ilb_name}-dgm"
  target_resource_id         = azurerm_lb.ilb.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.lag.id

  log {
    category = "LoadBalancerAlertEvent"
    enabled  = true

    retention_policy {
      enabled = true
      days    = "30"
    }
  }

  log {
    category = "LoadBalancerProbeHealthStatus"
    enabled  = true

    retention_policy {
      enabled = true
      days    = "30"
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = "30"
    }
  }
  depends_on = [azurerm_lb.ilb]
}

locals {

  public_ip_prefix_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group}/providers/Microsoft.Network/publicIPPrefixes/${local.elb_name}-ppp01"
}
resource "azurerm_linux_virtual_machine_scale_set" "linux_nvavss" {

  name                            = local.nva_name
  location                        = var.location
  resource_group_name             = var.resource_group
  computer_name_prefix            = local.nva_name
  admin_username                  = var.useradmin
  admin_password                  = data.azurerm_key_vault_secret.sicKeySecret.value
  disable_password_authentication = false
  instances                       = var.instances
  custom_data                     = base64encode("#!/usr/bin/python3 /etc/cloud_config.py\ninstallationType=\"${local.installationType}\"\nallowUploadDownload=\"${local.allowUploadDownload}\"\nosVersion=\"${local.osVersion}\"\ntemplateName=\"${local.templateName}\"\nisBlink=\"${local.isBlink}\"\ntemplateVersion=\"${local.templateVersion}\"\nbootstrapScript64=\"${local.bootstrapScript64}\"\nlocation=\"${var.location}\"\nsicKey=\"${data.azurerm_key_vault_secret.sicKeySecret.value}\"\nmanagementGUIClientNetwork=\"${local.managementGUIClientNetwork}\"\nvnet=\"${data.azurerm_virtual_network.vnet.address_space[0]}\"")
  plan {
    name      = local.sku
    publisher = local.publisher
    product   = var.offer
  }
  # automatic rolling upgrade
  upgrade_mode = "Manual"
  sku          = var.vmss_sku
  zones        = var.zones
  zone_balance = length(var.zones) > 0 ? "true" : "false"
  source_image_reference {
    publisher = local.publisher
    offer     = var.offer
    sku       = local.sku
    version   = var.ver
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  network_interface {
    name                          = "eth0"
    primary                       = true
    enable_accelerated_networking = true
    enable_ip_forwarding          = false
    ip_configuration {
      name                                   = "ipconfig1"
      primary                                = true
      subnet_id                              = data.azurerm_subnet.snt_front_name.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.elb_pool.id]
      public_ip_address {
        name                    = "instancePublicIP"
        idle_timeout_in_minutes = 30
        domain_name_label       = local.nva_name
        public_ip_prefix_id     = local.public_ip_prefix_id
      }
    }
  }
  network_interface {
    name                          = "eth1"
    primary                       = false
    enable_accelerated_networking = true
    enable_ip_forwarding          = true
    ip_configuration {
      name                                   = "ipconfig2"
      subnet_id                              = data.azurerm_subnet.snt_back_name.id
      primary                                = true
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.ilb_pool.id]
    }
  }
  boot_diagnostics {
    storage_account_uri = "https://${var.sa_name}.blob.core.windows.net/"
  }
  tags = {
    provider                    = "30DE18BC-F9F6-4F22-9D30-54B8E74CFD5F"
    x-chkp-anti-spoofing        = "eth0:false,eth1:false"
    x-chkp-ip-address           = "public"
    x-chkp-management           = var.managementServer
    x-chkp-management-interface = "eth0"
    x-chkp-srcImageUri          = "noCustomUri"
    x-chkp-template             = local.configurationTemplate
    x-chkp-topology             = "eth0:external,eth1:internal"
  }
  depends_on = [data.azurerm_public_ip_prefix.data_pip_prefix, azurerm_lb_backend_address_pool.ilb_pool, azurerm_lb_backend_address_pool.elb_pool]
}

// Configure autoscale settings for the Virtual Machine Scale Set

resource "azurerm_monitor_autoscale_setting" "autoscalesettings" {
  name                = local.nva_name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.linux_nvavss.id
  location            = var.location
  resource_group_name = var.resource_group

  profile {
    name = "autoscale-cpu"

    capacity {
      default = local.nvaminnodes
      minimum = local.nvaminnodes
      maximum = local.nvamaxnodes
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.linux_nvavss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 80
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.linux_nvavss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 60
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}
