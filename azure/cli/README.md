# Azure Trustle Connector


Create an application in Azure for the Trustle Connector using the Azure CLI.

This requires appropriate access for the Azure CLI. Refer to the
[Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
for further information.

## Example

This is an example of configuring the Trustle Connector for Azure via the `az`
CLI. It will need to be customized for your specific environment and
requirements.

For example, if the Trustle Connector will be read-only, syncing users and
groups from Azure but not updating them, then the `GroupMember.ReadWrite.All`
access is not needed.

Additionally, the application secret can be manually obtained from the Azure
console instead of with the Azure CLI. In which case, skip that step.

The Trustle URL for the organization is required to configure the OAuth callback
URL.

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

### Login to Azure

Set up Azure credentials first - refer to Azure CLI documentation. The TENANT_ID
is the GUID of the directory to which the Trustle Connector will be attached.

Login to azure:

```
TENANT_ID=4b1f48d8-ca84-62c6-b160-ebcb728589d0

az login --tenant ${TENANT_ID}
```

### Create the Trustle Connector application

The OAuth callback (reply) needs to be the URL used to access Trustle for the
organization. This is the same base URL used to access Trustle in the browser
and should look like `https://MY-ORG.trustle.io`. This needs to be set in
`TRUSTLE_URL` in the example. **Be sure TRUSTLE_URL is formatted exactly as
shown - if not correctly formatted or it contains extraneous information, such
as a trailing slash, there will be an error later when configuring the
connector.**

Edit [connector-app-access.json](connector-app-access.json) as required. The
default access policies include `GroupMember.ReadWrite.All` which can be
removed if the Trustle Connector will only be used to retrieve information from
Azure into Trustle, but not update group membership in Azure.

Create the Trustle Connector application:

```
TRUSTLE_URL=https://MY-ORG.trustle.io
APP_NAME="Trustle Connector"

az ad app create \
--display-name ${APP_NAME} \
--reply-urls "${TRUSTLE_URL}/api/connect/azure_ad/oauth" \
--required-resource-accesses @connector-app-access.json
```

Be sure to save the `appId` in the response JSON. This can also be found in
the Azure console for the application registration on the "Overview" page as
"Application (client) ID". The directory tenant ID is also required, which can
be found under "Directory (tenant) ID" on the same tab.

**Note that an Administrator must go into the Azure console and consent to
application access by clicking the "Grant admin consent for ..." button on the
"API Permissions" page.**

### Generate a password for the application service account

A password needs to be provided to the connector application. This example
uses the `pwgen` command to generate a random one. This password will need to
be provided to Trustle when setting up the connector. Alternatively, the
password can be created in the Azure console. The application ID is required
from the previous step, set in `APP_ID` here.

**Note: A password can be generated in the Azure portal instead of using the
CLI. Skip this step in that case, but note the secret is required when
configuring the connector in Trustle.**

Generate password:

```
APP_ID=e825eb08-0a8c-f5d3-9d14-3c96af56b26c
APP_PWD=$(pwgen 38 1)
az ad app credential reset --id ${APP_ID} --password ${APP_PWD}
```

The output of this command will include a `password` field containing the
application secret. This value is provided to Trustle during connector
configuration.

**Note the password will be shown in the output of the above command.
Alternatively, a password can be generated in the Azure portal for the
application instead.**

### Authorize application to Azure subscription

This step will authorize the Trustle Connector application to the Azure
subscription. The application ID is required, set in `APP_ID` here. The
subscription ID is also required, specified in `SUB_ID` here. This can be
found in the Azure console for the active subscription.

Authorize application:

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

If all the above was executed in the same shell session, you can echo the
variables for values to configure the Azure Connector in Trustle:

```
echo "Directory (tenant) ID       : $TENANT_ID"
echo "Application (client) ID     : $APP_ID"
echo "Client credentials (secret) : $APP_PWD"
```

**If a password was generated in the Azure console, use that generated value
instead, and don't echo APP_PWD.**
