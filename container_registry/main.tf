terraform {
  required_version = ">= 1.12.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "time_rotating" "token_password_rotation_01" {
  rotation_years = 1

  triggers = {
    year = formatdate("YYYY", plantimestamp())
  }
}

resource "time_rotating" "token_password_rotation_02" {
  rotation_years = 1

  triggers = {
    # Offset by half the rotation period to stagger password rotations
    year = formatdate("YYYY", timeadd(plantimestamp(), format("-%dh", 1 * 365 * 24 / 2)))
  }
}

resource "azurerm_resource_group" "acr_test" {
  name     = "acr-test-rg"
  location = "Norway East"
}

resource "azurerm_container_registry" "acr" {
  name                = "testacrregistry12345"
  resource_group_name = azurerm_resource_group.acr_test.name
  location            = azurerm_resource_group.acr_test.location
  sku                 = "Basic"
}

resource "azurerm_container_registry_scope_map" "scope_map" {
  name                    = "${azurerm_container_registry.acr.name}-scope-map"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = azurerm_container_registry.acr.resource_group_name
  actions                 = ["repositories/*/content/read"]
}

resource "azurerm_container_registry_token" "token" {
  name                    = "${azurerm_container_registry.acr.name}-token"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = azurerm_container_registry.acr.resource_group_name
  scope_map_id            = azurerm_container_registry_scope_map.scope_map.id
  enabled                 = true

  lifecycle {
    ignore_changes = [scope_map_id]
  }
}

resource "azurerm_container_registry_token_password" "token_password" {
  container_registry_token_id = azurerm_container_registry_token.token.id

  password1 {
    expiry = time_rotating.token_password_rotation_01.rotation_rfc3339
  }

  password2 {
    expiry = time_rotating.token_password_rotation_02.rotation_rfc3339
  }
}

output "time_rotating_01" {
  description = "The rotation timestamp for the first token password."
  value       = time_rotating.token_password_rotation_01.rotation_rfc3339
}

output "time_rotating_02" {
  description = "The rotation timestamp for the second token password."
  value       = time_rotating.token_password_rotation_02.rotation_rfc3339
}

output "token_password1_expiry" {
  description = "The expiry date of the first token password."
  value       = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", azurerm_container_registry_token_password.token_password.password1[0].expiry)
}

output "token_password2_expiry" {
  description = "The expiry date of the second token password."
  value       = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", azurerm_container_registry_token_password.token_password.password2[0].expiry)
}
