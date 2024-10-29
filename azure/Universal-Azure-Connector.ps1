Install-Module Az -Scope CurrentUser
az login

Set-PSRepository "PSGallery" -InstallationPolicy Trusted

Import-Module Microsoft.Graph.Applications
Connect-MgGraph -scopes "User.Read.All, Policy.Read.All, Policy.ReadWrite.Authorization, Application.Read.All, `
Application.ReadWrite.All, Directory.Read.All, Directory.ReadWrite.All, Directory.ReadWrite.All, Application.Read.All, `
Application.ReadWrite.All, Directory.Read.All, Directory.ReadWrite.All, AppRoleAssignment.ReadWrite.All, `
DelegatedPermissionGrant.ReadWrite.All"

Install-Module Microsoft.Graph.Users

#-------------------------------------------------------------
# Function to create a new Azure or 365 Application

function Add-AzureApplication {

    param(
        [string]$appName,
        [string]$RedirectURI
    )

    # $ReplyURL = Read-Host "Enter your redirect URI"
    $App = New-MgApplication -DisplayName $AppName -Web @{ RedirectUris = @($RedirectURI) }

    New-MgServicePrincipal -AppId $App.AppId
}

function Add-M365Application {

    param(
        [string]$appName
    )

    $App = New-MgApplication -DisplayName $AppName

    New-MgServicePrincipal -AppId $App.AppId
}

# -------------------------------------------------------------
# Function to Add Delegated Permissions

function Add-DelegatedPermission {

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
        "GroupMember.ReadWrite.All",
        "Reports.Read.All"
    )

    $filteredDelegatedPermissions = Get-MgServicePrincipal -Filter "displayName eq 'Microsoft Graph'" `
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
                resourceAccess = $filteredDelegatedPermissions | ForEach-Object {
                    @{
                        id = $_.Id
                        type = "Scope"
                    }
                }
            }
        )
    }

    Update-MgApplication -ApplicationId $app.Id -BodyParameter $params

    Write-Host -ForegroundColor Cyan "Added delegated permissions to app registration"

}

# -------------------------------------------------------------
# Function to Add Application Permissions

function Add-ApplicationPermission {

    param(
        [string]$appName
    )

    $app = Get-MgApplication -Filter "DisplayName eq '$appName'"

    $graphAppId = "00000003-0000-0000-c000-000000000000"

    $graphServicePrincipal = Get-MgServicePrincipal -Filter ("appId eq '" + $graphAppId + "'") -ErrorAction Stop
    $graphAppPermissions = $graphServicePrincipal.AppRoles

    $appServicePrincipal = Get-MgServicePrincipal -Filter "DisplayName eq '$appName'"

    $resourceAccess = @()

    $TrustleGraphScopes = @(
        'AuditLog.Read.All',
        'Directory.Read.All',
        'Directory.ReadWrite.All',
        'Group.Read.All',
        'Group.ReadWrite.All',
        'GroupMember.Read.All',
        'GroupMember.ReadWrite.All',
        'Sites.FullControl.All',
        'User.Read.All',
        'User.ReadWrite.All',
        'Organization.ReadWrite.All',
        'Reports.Read.All'
    )

    foreach($scope in $TrustleGraphScopes)
    {
        $permission = $graphAppPermissions | Where-Object { $_.Value -eq $scope }
        if ($permission)
        {
            $resourceAccess += @{ Id =  $permission.Id; Type = "Role"}
        }
        else
        {
            Write-Host -ForegroundColor Red "Invalid scope:" $scope
            Exit
        }
    }

    # Add the permissions to required resource access
    Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess `
    @{ ResourceAppId = $graphAppId; ResourceAccess = $resourceAccess } -ErrorAction Stop
    Write-Host -ForegroundColor Cyan "Added application permissions to app registration"


    # Add admin consent
    foreach ($appRole in $resourceAccess)
    {
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $appServicePrincipal.Id `
        -PrincipalId $appServicePrincipal.Id -ResourceId $graphServicePrincipal.Id `
        -AppRoleId $appRole.Id -ErrorAction SilentlyContinue -ErrorVariable SPError | Out-Null
        if ($SPError)
        {
            Write-Host -ForegroundColor Red "Admin consent for one of the requested scopes could not be added."
            Write-Host -ForegroundColor Red $SPError
            Exit
        }
    }
    Write-Host -ForegroundColor Cyan "Added admin consent"

}


# -------------------------------------------------------------
# Function to add Delegated Permission Admin Consent

function Add-DelegatedAdminConsent {

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
        scope = "AuditLog.Read.All Directory.Read.All User.Read.All offline_access Group.Read.All GroupMember.Read.All GroupMember.ReadWrite.All Reports.Read.All"
    }

    New-MgOauth2PermissionGrant -BodyParameter $params1

    $params2 = @{
        clientId = $clientId
        consentType = "AllPrincipals"
        resourceId = $resourceId2
        scope = "user_impersonation"
    }

    New-MgOauth2PermissionGrant -BodyParameter $params2

    Write-Host -ForegroundColor Cyan "Added admin consent"

}

# -------------------------------------------------------------
# Function to add Reader Role

function Add-ReaderRole {

    param(
        $appName
    )
    $spId = (Get-AzADServicePrincipal -DisplayName $appName).Id
    # $spId = (Get-AzureADServicePrincipal -Filter "DisplayName eq '$($appName)'").ObjectId
    $subscriptionId = (Get-AzContext).Subscription.id
    New-AzRoleAssignment -ObjectId $spId -RoleDefinitionName "Reader" -Scope "/subscriptions/$subscriptionId"

}

#-------------------------------------------------------------
# Create your application

Do {
    $RedirectURI=$args[0].ToString()
    $AzureOr365 = Read-Host "Which Trustle Connector do you wish to install for, 1) Azure, or 2) M365? Enter '1' or '2'"


    If (!(($AzureOr365 -eq '1') -or ($AzureOr365 -eq '2'))) {
        "Invalid Answer, try again."
    }
    Elseif ($AzureOr365 -eq '1') {
        # Create Azure Application
        
        if (!$RedirectURI) {
            $RedirectURI = Read-Host "Enter your redirect URI"
        }

        $appName = Read-Host "Name your Application"
        Add-AzureApplication $appName $RedirectURI
        Start-Sleep -Seconds 1
        Add-DelegatedPermission $appName
        Start-Sleep -Seconds 1
        Add-DelegatedAdminConsent $appName
        Start-Sleep -Seconds 1
        Add-ReaderRole $appName
        Start-Sleep -Seconds 1

        $App = Get-MgApplication -Filter "DisplayName eq '$appName'"

        $passwordCred = @{
            displayName = 'Password Credential'
        }

        $secret = Add-MgApplicationPassword -applicationId $App.Id -PasswordCredential $passwordCred


        # Output the application details
        Write-Output "Azure AD Application Created:"
        Write-Output " "
        Write-Output "Application Name: $($App.DisplayName)"
        Write-Output " "
        Write-Output "Directory (tenant) ID: $((Get-AzTenant).Id | Select-Object -First 1)"
        Write-Output "Application (client) ID: $($App.AppId)"
        Write-Output "Secret (Password Credential): $($secret.SecretText)"
    }
    Elseif ($AzureOr365 -eq '2') {
        # Create M365 Application

        $appName = Read-Host "Name your Application"
        Add-M365Application $appName
        Start-Sleep -Seconds 1
        Add-ApplicationPermission $appName
        Start-Sleep -Seconds 1

        $App = Get-MgApplication -Filter "DisplayName eq '$appName'"

        $passwordCred = @{
            displayName = 'Password Credential'
        }

        $secret = Add-MgApplicationPassword -applicationId $App.Id -PasswordCredential $passwordCred


        # Output the application details
        Write-Output "M365 Application Created:"
        Write-Output " "
        Write-Output "Application Name: $($App.DisplayName)"
        Write-Output " "
        Write-Output "Directory (tenant) ID: $((Get-AzTenant).Id | Select-Object -First 1)"
        Write-Output "Application (client) ID: $($App.AppId)"
        Write-Output "Secret (Password Credential): $($secret.SecretText)"
    }
    Else {
        "Invalid Answer, restart code."
    }

    #end loop if answer exists, otherwise go to top and try again
} Until (($AzureOr365 -eq '1') -or ($AzureOr365 -eq '2'))
