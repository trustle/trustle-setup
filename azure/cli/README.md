# Azure Trustle Connector


Create an application in Azure for the Trustle Connector using the Azure CLI.

This requires appropriate access for the Azure CLI. Refer to the
[Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
for further information.

## Example

This is an example of configuring the Trustle Connector for Azure via the CLI.
It will need to be customized for your specific environment and requirements.

For example, if the Trustle Connector will be read-only, syncing users and
groups from Azure but not updating them, then the `GroupMember.ReadWrite.All`
access is not needed.

Additionally, the application secret can be manually obtained from the Azure
console instead of with the Azure CLI. In which case, skip that step.

The Hostname of the organization in Trustle is required to configure the
OAuth callback URL.

## Configuration

A few configuration choices are required or can be set - such as the name of
the Trustle Connector application and the organization hostname already
mentioned.

The example performs the following actions in Azure:

+ Creates an Azure application for the Trustle Connector. Default:
  `Trustle Connector`.
+ Configures an OAuth callback URL.
+ Configures access policies for the application.
+ Configures the `Reader` role for the Trustle Connector application on the
  Azure subscription.
+ Creates a secret for the created application service account. This part of
  the example can be removed to manually create access keys in the Azure
  console.

## Usage

The user executing the Azure CLI commands must have appropriate Administrative
access to the Azure subscription and directory.

### Create the Trustle Connector application.

Edit [connector-app-access.json](connector-app-access.json). The
OAuth callback URL hostname will need to be modified with the organization
name (`ORG_HOSTNAME` below). Additionally, the default access policies include
`GroupMember.ReadWrite.All` which can be removed if the Trustle Connector will
only be used to retrieve information from Azure into Trustle.

```
# Set up Azure credentials first - refer to Azure CLI documentation

ORG_HOSTNAME=my-org
APP_NAME="Trustle Connector"

az ad app create \
--display-name ${APP_NAME} \
--reply-urls "https://${ORG_HOSTNAME}.trustle.io/api/connect/azure_ad/oauth" \
--required-resource-accesses @connector-app-access.json
```

Be sure to save the `appId` in the response JSON. This can also be found in
the Azure console for the application registration on the "Overview" page as
"Application (client) ID". The directory tenant ID is also required, which can
be found under "Directory (tenant) ID" on the same tab.

Note that an Administrator must go into the Azure console and consent to
application access by clicking the "Grant admin consent for ..." button on the
"API Permissions" page.

### Generate a password for the application service account

A password needs to be provided to the connector application. This example
uses the `pwgen` command to generate a random one. This password will need to
be provided to Trustle when setting up the connector. Alternatively, the
password can be created in the Azure console. The application ID is required
from the previous step, set in `APP_ID` here.

```
APP_ID=e825eb08-0a8c-f5d3-9d14-3c96af56b26c
APP_PWD=$(pwgen 38)
az ad app credential reset --id ${APP_ID} --password ${APP_PWD}
```

The output of this command will include a `password` field containing the
application secret. This value is provided to Trustle during connector
configuration.

### Authorize application to Azure subscription

This step will authorize the Trustle Connector application to the Azure
subscription. The application ID is required, set in `APP_ID` here. The
subscription ID is also required, specified in `SUB_ID` here. This can be
found in the Azure console for the active subscription.

```
APP_ID=e825eb08-0a8c-f5d3-9d14-3c96af56b26c
SUB_ID=5fa002e9-cdb5-f312-47a5-2e037feb329e

az role assignment create \
--assignee ${APP_ID} \
--role "Reader" \
--subscription ${SUB_ID}
```

### Create connector in Trustle

The directory tenant ID, connector application ID, and client secret are
provided to Trustle when configuring an automated Azure resource management
system within the Trustle management UI.
