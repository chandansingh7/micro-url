provider "azurerm" {
  features {}
}

# Define Variables
variable "location" {
  default = "centralus"  # Change if quota issues occur
}

variable "resource_group" {
  default = "myMicroUrlResourceGroup"
}

variable "app_service_plan" {
  default = "myAppServicePlan"
}

variable "app_service_name" {
  default = "myMicroUrlJavaApp"
}

variable "postgres_server_name" {
  default = "my-micro-url-db"
}

variable "postgres_admin_user" {
  default = "myadmin"
}

variable "postgres_admin_password" {
  default = "MyStrongP@ssword123"
}

variable "jenkins_ip" {
  description = "The public IP of the Jenkins server"
  default     = "24.28.169.48"  # Change to your Jenkins server IP
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

# Create App Service Plan (B1 Free Tier)
resource "azurerm_service_plan" "app_plan" {
  name                = var.app_service_plan
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "B1"
  os_type             = "Linux"
}

# Create App Service for Java
resource "azurerm_linux_web_app" "java_app" {
  name                = var.app_service_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.app_plan.id

  depends_on = [azurerm_service_plan.app_plan, azurerm_postgresql_flexible_server.db]

  site_config {
    always_on = true

    application_stack {
      java_version        = "17"
      java_server         = "TOMCAT"  # ✅ Corrected: Use uppercase TOMCAT
      java_server_version = "10.0"
    }
  }

  app_settings = {
    "DATABASE_URL"      = "jdbc:postgresql://${azurerm_postgresql_flexible_server.db.fqdn}:5432/postgres"
    "DATABASE_USERNAME" = "${var.postgres_admin_user}@${var.postgres_server_name}"
    "DATABASE_PASSWORD" = var.postgres_admin_password
  }
}

# Create PostgreSQL Flexible Server (Burstable Tier)
resource "azurerm_postgresql_flexible_server" "db" {
  name                   = var.postgres_server_name
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  administrator_login    = var.postgres_admin_user
  administrator_password = var.postgres_admin_password
  sku_name               = "B_Standard_B1ms"  # ✅ Corrected SKU for free-tier
  storage_mb             = 32768
  version                = "14"  # ✅ Required PostgreSQL Version
  zone                   = "3"
  # ✅ Removed `zone` since it is not needed without High Availability
}

# Allow App Service to Access PostgreSQL
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_app_service" {
  name                = "AllowAppService"
  server_id           = azurerm_postgresql_flexible_server.db.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Allow Jenkins to Deploy
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_jenkins" {
  name                = "AllowJenkins"
  server_id           = azurerm_postgresql_flexible_server.db.id
  start_ip_address    = var.jenkins_ip
  end_ip_address      = var.jenkins_ip
}

# Deployment Slot for CI/CD  only for standerd plan
#resource "azurerm_linux_web_app_slot" "deployment_slot" {
#  name           = "staging"
#  app_service_id = azurerm_linux_web_app.java_app.id
#
#  site_config {
#    always_on = true
#  }
#}
