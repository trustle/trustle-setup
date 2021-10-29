# Azure Trustle Connector


This Terraform template will create an application in Azure for the Trustle
Connector.

Using this template requires appropriate access for the Azure Terraform
provider. Refer to the
[Terraform Azure Active Directory](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs)
and
[Terraform Azure Resource Manager](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
documentation for further information.

## Example

This Terraform template is an example. It will need to be customized for your
specific environment and requirements.

For example, if the Trustle Connector will be read-only, syncing users and
groups from Azure but not updating them, then the `GroupMember.ReadWrite.All`
access is not needed.

Additionally, the application secret can be manually obtained from the Azure
console or Azure CLI instead of automatically with this template, in which
case the template needs to be edited to skip this step.

The `trustle-org-name` variable must be set to the hostname of the
organization in Trustle.

## Configuration

A few configuration variables are supported - such as the name of the Trustle
Connector application and the organization hostname already mentioned.

The template performs the following actions in Azure:

+ Creates an Azure application for the Trustle Connector. Default:
  `Trustle Connector`.
+ Configures an OAuth callback URL.
+ Configures access policies for the application.
+ Creates a secret for the created application service account. This part of
  the template can be removed to manually create a secret via the Azure
  console or Azure CLI.

**Important: The Terraform template uses the `azuread_application_password`
resource to create an Azure secret for the Trustle Connector application. These
credentials are stored in the Terraform state file.** To avoid any potential
exposure of these sensitive credentials, remove the outputs and resource from
the Terraform template and obtain this secret manually via the Azure console or
Azure CLI.

## Usage

Before applying this template please insure it has been modified for your usage.

```
# Set up Azure credentials first - refer to Terraform Azure documentation

$ terraform init

$ terraform apply -var 'trustle-org-name=ORG_HOSTNAME'

# Optionally obtain secret for the application

$ terraform output connector_client_secret

```

Note that an Administrator must go into the Azure console and consent to
application access, then add the Trustle Connector application to the
`Reader` role on the Azure subscription.

To consent the application permissions, navigate to the application in the
Azure console and click the "Grant admin consent for ..." button on the
"API Permissions" page.

The directory tenant ID, connector application ID, and client secret are
provided to Trustle when configuring an automated Azure resource management
system within the Trustle management UI.
