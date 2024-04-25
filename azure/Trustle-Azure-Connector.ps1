Install-Module Az -Scope CurrentUser
az login

Set-PSRepository "PSGallery" -InstallationPolicy Trusted

Import-Module Microsoft.Graph.Applications
Connect-MgGraph -scopes "User.Read.All, Policy.Read.All, Policy.ReadWrite.Authorization, Application.Read.All, `
Application.ReadWrite.All, Directory.Read.All, Directory.ReadWrite.All, Directory.ReadWrite.All, Application.Read.All, `
Application.ReadWrite.All, Directory.Read.All, Directory.ReadWrite.All, AppRoleAssignment.ReadWrite.All, `
DelegatedPermissionGrant.ReadWrite.All"

#-------------------------------------------------------------
# Function to create a new Azure AD application

function Add-Application {

    param(
        [string]$appName
    )

    $ReplyURL = Read-Host "Enter your redirect URI"
    $App = New-MgApplication -DisplayName $AppName -Web @{ RedirectUris = @($ReplyURL) }

    New-MgServicePrincipal -AppId $App.AppId
}

# -------------------------------------------------------------
# Function to Add Permissions

function Add-Permission {

    param(
        [string]$appName
    )

    $delegatedPermissions = @(
        "AuditLog.Read.All",
        "Directory.Read.All",
        "User.Read.All",
        "offline_access",
        "Group.Read.All",
        "GroupMember.Read.All",
        "GroupMember.ReadWrite.All"
    )

    $filteredPermissions = Get-MgServicePrincipal -Filter "displayName eq 'Microsoft Graph'" `
    -Property Oauth2PermissionScopes | Select-Object -ExpandProperty Oauth2PermissionScopes | `
    Where-Object { $delegatedPermissions -contains $_.Value }

    $azureServicePermission = @{
        resourceAppId = "797f4846-ba00-4fd7-ba43-dac1f8f63013"
        resourceAccess = @(
            @{
                id = "41094075-9dad-400e-a0bd-54e686782033"
                type = "Scope"
            }
        )
    }

    $app = Get-MgApplication -Filter "DisplayName eq '$appName'"

    $params = @{
        requiredResourceAccess = @(
            $azureServicePermission,
            @{
                resourceAppId = "00000003-0000-0000-c000-000000000000"
                resourceAccess = $filteredPermissions | ForEach-Object {
                    @{
                        id = $_.Id
                        type = "Scope"
                    }
                }
            }
        )
    }

    Update-MgApplication -ApplicationId $app.Id -BodyParameter $params
}


# -------------------------------------------------------------
# Function to add Admin Consent

function Add-AdminConsent {

    param(
        [string]$appName
    )

    $clientId = (Get-MgServicePrincipal -Filter "DisplayName eq '$appName'").Id
    $resourceId1 = (Get-MgOauth2PermissionGrant | Where-Object { $_.Scope -contains "User.Read" }).ResourceId | Select-Object -First 1
    $resourceId2 = (Get-MgOauth2PermissionGrant | Where-Object { $_.Scope -eq "user_impersonation" }).ResourceId | Select-Object -First 1

    $params1 = @{
        clientId = $clientId
        consentType = "AllPrincipals"
        resourceId = $resourceId1
        scope = "AuditLog.Read.All Directory.Read.All User.Read.All offline_access Group.Read.All GroupMember.Read.All GroupMember.ReadWrite.All"
    }

    New-MgOauth2PermissionGrant -BodyParameter $params1

    $params2 = @{
        clientId = $clientId
        consentType = "AllPrincipals"
        resourceId = $resourceId2
        scope = "user_impersonation"
    }

    New-MgOauth2PermissionGrant -BodyParameter $params2

}

# -------------------------------------------------------------
# Function to add Reader Role

function Add-ReaderRole {

    param(
        $appName
    )
    $spId = (Get-AzADServicePrincipal -DisplayName $appName).Id
    $subscriptionId = (Get-AzContext).Subscription.id
    New-AzRoleAssignment -ObjectId $spId -RoleDefinitionName "Reader" -Scope "/subscriptions/$subscriptionId"

}

#-------------------------------------------------------------
# Create your application

$appName = Read-Host "Name your Application"
Add-Application $appName
Add-Permission $appName
Add-AdminConsent $appName
Add-ReaderRole $appName

$App = Get-MgApplication -Filter "DisplayName eq '$appName'"

$passwordCred = @{
    displayName = 'Password Credenital'
 }

 $secret = Add-MgApplicationPassword -applicationId $App.Id -PasswordCredential $passwordCred


# Output the application details
Write-Output "Azure AD Application Created:"
Write-Output " "
Write-Output "Application Name: $($App.DisplayName)"
Write-Output " "
Write-Output "Directory (tenant) ID: $((Get-AzTenant).Id)"
Write-Output "Application (client) ID: $($App.AppId)"
Write-Output "Secret (Password Credential): $($secret.SecretText)"