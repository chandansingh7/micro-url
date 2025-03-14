provider "azurerm" {
  features {}
}

# Define Variables
variable "location" {
  default = "centralus"
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

variable "function_app_name" {
  default = "myMicroUrlFunctionApp"
}

variable "storage_account_name" {
  default = "mymicroulstorage"
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
  default     = "24.28.169.48"
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

# Create Storage Account for Function App
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create App Service Plan
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
      java_server         = "TOMCAT"
      java_server_version = "10.0"
    }
  }

  app_settings = {
    "DATABASE_URL"      = "jdbc:postgresql://${azurerm_postgresql_flexible_server.db.fqdn}:5432/postgres"
    "DATABASE_USERNAME" = "${var.postgres_admin_user}@${var.postgres_server_name}"
    "DATABASE_PASSWORD" = var.postgres_admin_password
  }
}

# Create Azure Function App
resource "azurerm_linux_function_app" "function_app" {
  name                      = var.function_app_name
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  service_plan_id           = azurerm_service_plan.app_plan.id
  storage_account_name      = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key

  site_config {
    application_stack {
      java_version = "17"
    }
  }

  app_settings = {
    "DATABASE_URL"      = "jdbc:postgresql://${azurerm_postgresql_flexible_server.db.fqdn}:5432/postgres"
    "DATABASE_USERNAME" = "${var.postgres_admin_user}@${var.postgres_server_name}"
    "DATABASE_PASSWORD" = var.postgres_admin_password
  }
}

# Create PostgreSQL Flexible Server (without High Availability)
resource "azurerm_postgresql_flexible_server" "db" {
  name                   = var.postgres_server_name
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  administrator_login    = var.postgres_admin_user
  administrator_password = var.postgres_admin_password
  sku_name               = "B_Standard_B1ms"  # ✅ Correct SKU for burstable tier
  storage_mb             = 32768
  version                = "14"

  # ✅ High Availability is removed to prevent zone errors
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
