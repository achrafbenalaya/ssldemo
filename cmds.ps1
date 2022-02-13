$sp = New-AzADServicePrincipal -DisplayName ServicePrincipalName

$sp.PasswordCredentials.SecretText

Connect-AzAccount
Get-AzADServicePrincipal

Get-Module -Name Az.* -ListAvailable 

$PSVersionTable.PSVersion

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force


Install-Module -Name Az -Repository PSGallery -Force
