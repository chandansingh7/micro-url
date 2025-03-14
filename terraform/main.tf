provider "azurerm" {
  features {}
}

# Fetch Tenant, Subscription, and Object ID dynamically
data "azurerm_client_config" "current" {}

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

variable "jenkins_ip" {
  default     = "24.28.169.48"
  description = "The public IP of the Jenkins server"
}

# 🔹 Generate Secure Database Credentials
resource "random_password" "postgres_password" {
  length  = 16
  special = false
}

# 🔹 Create a New Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

# 🔹 Create Azure Key Vault for Secure Secrets Storage
resource "azurerm_key_vault" "kv" {
  name                        = "myMicroUrlKeyVault"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
}

# 🔹 Grant Key Vault Access Using `azurerm_key_vault_access_policy`
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set"]
}

# 🔹 Store Database Credentials in Key Vault
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = random_password.postgres_password.result
  key_vault_id = azurerm_key_vault.kv.id
}

# 🔹 Create Storage Account for Function App
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 🔹 Create App Service Plan (Linux)
resource "azurerm_service_plan" "app_plan" {
  name                = var.app_service_plan
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "B1"
  os_type             = "Linux"
}

# 🔹 Create Web App for Java (✅ Fixed Java Stack Configuration)
resource "azurerm_linux_web_app" "java_app" {
  name                = var.app_service_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.app_plan.id

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
    "DATABASE_USERNAME" = "myadmin@${var.postgres_server_name}"
    "DATABASE_PASSWORD" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_password.id})"
  }
}

# 🔹 Create Azure Function App (Running on Java)
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
    "DATABASE_USERNAME" = "myadmin@${var.postgres_server_name}"
    "DATABASE_PASSWORD" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_password.id})"
  }
}

# 🔹 Create PostgreSQL Flexible Server (✅ Fixed Availability Zone Issue)
resource "azurerm_postgresql_flexible_server" "db" {
  name                   = var.postgres_server_name
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  administrator_login    = "myadmin"
  administrator_password = random_password.postgres_password.result
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  version                = "14"

}

# 🔹 Allow App Service to Access PostgreSQL
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_app_service" {
  name             = "AllowAppService"
  server_id        = azurerm_postgresql_flexible_server.db.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# 🔹 Allow Jenkins to Deploy
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_jenkins" {
  name             = "AllowJenkins"
  server_id        = azurerm_postgresql_flexible_server.db.id
  start_ip_address = var.jenkins_ip
  end_ip_address   = var.jenkins_ip
}
