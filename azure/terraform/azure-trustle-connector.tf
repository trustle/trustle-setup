# Terraform template to configure Azure for the Trustle Connector.
#
# This creates Azure policies and a user for the connector, along with access
# keys for the connector user. After executing this Terraform, an administrator
# must grant consent for the application via the Azure console, as well as a
# role assignment for the application to the Azure subscription.
#
# Copyright 2021 Trustle, Inc.
# Licensed under the Apache License, Version 2.0


#
# Variables
#

variable "trustle-connector-user" {
  description = "Azure username for trustle connector"
  default     = "Trustle Connector"
}

variable "trustle-url" {
  description = "Trustle URL for Organization - 'https://MY-ORG.trustle.io'"
}

#
# Outputs
#

output "directory_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "connector_application_id" {
  value = resource.azuread_application.trustle-connector.application_id
}

# Remove this to manually create secret in the Azure console
output "connector_client_secret" {
  value = resource.azuread_application_password.trustle-connector.value
  sensitive = true
}

#
# General
#

provider "azuread" {
}

provider "azurerm" {
  features {
  }
}

data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "current" {
}

#
# Connector application
#

resource "azuread_application" "trustle-connector" {
  display_name     = var.trustle-connector-user
  sign_in_audience = "AzureADMyOrg"

  web {
    redirect_uris = ["${var.trustle-url}/api/connect/azure_ad/oauth"]
  }

  required_resource_access {
    resource_app_id = "797f4846-ba00-4fd7-ba43-dac1f8f63013"  # Service Mgmt

    resource_access {
      id   = "41094075-9dad-400e-a0bd-54e686782033" # user_impersonation
      type = "Scope"
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"  # MS Graph

    resource_access {
      id   = "7427e0e9-2fba-42fe-b0c0-848c9e6a8182" # offline_access
      type = "Scope"
    }

    resource_access {
      id   = "a154be20-db9c-4678-8ab7-66f6cc099a59" # User.Read.All
      type = "Scope"
    }

    resource_access {
      id   = "5f8c59db-677d-491f-a6b8-5f174b11ec1d" # Group.Read.All
      type = "Scope"
    }
    resource_access {
      id   = "06da0dbc-49e2-44d2-8312-53f166ab848a" # Directory.Read.All
      type = "Scope"
    }

    resource_access {
      id   = "e4c9e354-4dc5-45b8-9e7c-e1393b0b1a20" # AuditLog.Read.All
      type = "Scope"
    }

    # Remove this for read-only access
    resource_access {
      id   = "f81125ac-d3b7-4573-a3b2-7099cc39df9e" # GroupMember.ReadWrite.All
      type = "Scope"
    }

  }
}

# Remove this to manually create secrets in the Azure console
resource "azuread_application_password" "trustle-connector" {
  application_object_id = azuread_application.trustle-connector.object_id
  display_name          = var.trustle-connector-user
}

# Add role for the application to the subscription
# Not currently working
# https://github.com/hashicorp/terraform-provider-azurerm/issues/669
# https://github.com/hashicorp/terraform-provider-azurerm/issues/12592
#resource "azurerm_role_assignment" "trustle-connector" {
  #scope                            = data.azurerm_subscription.primary.id
  #role_definition_name             = "Reader"
  #principal_id                     = resource.azuread_application.trustle-connector.object_id
  #skip_service_principal_aad_check = true
#}
