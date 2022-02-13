param(
  [Parameter(Mandatory = $False, Position = 0, ValueFromPipeline = $false)]
  [System.Int32]
  $minimumCertAgeDays = 30
)

$NameList = @('https://achrafbenalaya.com', 'https://assurance-carte.europ-assistance.fr')
#$urls = get-content C:\readlistUrls.txt
$Results = @()
$dnsServer = @('8.8.8.8', '8.8.4.4')

#SSL variables
#$minimumCertAgeDays = 60
$timeoutMilliseconds = 15000
#disabling the cert validation check. This is what makes this whole thing work with invalid certs...
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }


foreach ($Name in $NameList) {
  $OutputObject = "" | Select-Object Type, OriginUrl, Name, IPAddress, Status, SSLStartDAY, SSLENDDAY, SSENDINDAYS, StatusSSLMinAge, ErrorMessage 
  try {        
 
    $domain = ([System.URI]$Name).host.Trim()
    $dnsRecord = Resolve-DnsName $domain  -Server $dnsServer | Where-Object { $_.Type -eq 'A' }  -ErrorAction Stop           
    $OutputObject.Name = $dnsRecord.Name  
    $OutputObject.OriginUrl = $Name
    $OutputObject.Type = $dnsRecord.Type   
    $OutputObject.IPAddress = ($dnsRecord.IPAddress -join ',')     
    $OutputObject.Status = 'OK'     
    $OutputObject.ErrorMessage = ''    

    #SSL STUFF
    Write-Host Checking $Name -f Green
    $req = [Net.HttpWebRequest]::Create($Name)
    $req.Timeout = $timeoutMilliseconds
    $req.AllowAutoRedirect = $true
    try {
      $req.GetResponse() | Out-Null
    } 
    catch {
             
      Write-Host Exception while checking URL $Name`: $_ -f Red
    }

    $certExpiresOnString = $req.ServicePoint.Certificate.GetExpirationDateString()
    #Write-Host "Certificate expires on (string): $certExpiresOnString"
    [datetime]$expiration = [System.DateTime]::Parse($req.ServicePoint.Certificate.GetExpirationDateString())
    #Write-Host "Certificate expires on (datetime): $expiration"
    [int]$certExpiresIn = ($expiration - $(get-date)).Days
    $certName = $req.ServicePoint.Certificate.GetName()
    $certPublicKeyString = $req.ServicePoint.Certificate.GetPublicKeyString()
    $certSerialNumber = $req.ServicePoint.Certificate.GetSerialNumberString()
    $certThumbprint = $req.ServicePoint.Certificate.GetCertHashString()
    $certEffectiveDate = $req.ServicePoint.Certificate.GetEffectiveDateString()
    $certIssuer = $req.ServicePoint.Certificate.GetIssuerName()
    $OutputObject.SSLStartDAY = $certEffectiveDate 
    $OutputObject.SSLENDDAY = $expiration
    $OutputObject.SSENDINDAYS = $certExpiresIn 

    if ($certExpiresIn -gt $minimumCertAgeDays)
    {   
      Write-Host Cert for site $Name expires in $certExpiresIn days [on $expiration] -f Green  
      $OutputObject.StatusSSLMinAge = 'ok'    

    }
    else {
      
      Write-Host WARNING: Cert for site $Name expires in $certExpiresIn days [on $expiration] -f Red
      $OutputObject.StatusSSLMinAge = 'ko'    

    }


    #END SSL STUFF

  }  

  catch {      
    $OutputObject.Name = $Name       
    $OutputObject.IPAddress = ''       
    $OutputObject.Status = 'NOT_OK'     
    $OutputObject.ErrorMessage = $_.Exception.Message  
  }   

    $Results += $OutputObject
                
}


{
$Results | Export-Csv "$Env:temp/AutomationFile.csv" -NoTypeInformation
$Context = New-AzureStorageContext -StorageAccountName "sslsaveddata" -StorageAccountKey "vtBFJx7g9RV86Bb1SVcuFJYBj0FZwOS1rJU+7/R8PEh0PgyqeaclfL+CjStl8fbCvhCzetBvahXl+AStf+0RUw=="
Set-AzureStorageBlobContent -Context $Context -Container "ssldata" -File "$Env:temp/AutomationFile.csv" -Blob "SavedFile.csv"

}
              
return $Results 

#| Export-Csv "$Env:temp/AutomationFile.csv" -NoTypeInformation


