
 
param(
    [Parameter(Mandatory)]
    [string]$SiteName,
 
    [Parameter(Mandatory)]
    [string]$SitePhysicalPath,
 
    [int]$Port = 80,
 
    [int]$HttpsPort = 443,
 
    [Parameter(Mandatory)]
    [string]$HostHeader,
 
    # Se não informado, um certificado autoassinado é gerado para o HostHeader
    [string]$CertificateThumbprint,
 
    [Parameter(Mandatory)]
    [string]$GroupName,
 
    [Parameter(Mandatory)]
    [string]$UserName,
 
    [Parameter(Mandatory)]
    [securestring]$UserPassword,
 
    [Parameter(Mandatory)]
    [string]$AppPoolName,
 
    [Parameter(Mandatory)]
    [string]$LogFilePath,
 
    [Parameter(Mandatory)]
    [string]$AppName,
 
    [Parameter(Mandatory)]
    [string]$AppPhysicalPath
)
 
$ErrorActionPreference = "Stop"
 
Import-Module WebAdministration
 
# ---------------------------------------------------------------------------
# 1. Grupo local e usuário membro
# ---------------------------------------------------------------------------
if (-not (Get-LocalGroup -Name $GroupName -ErrorAction SilentlyContinue)) {
    New-LocalGroup -Name $GroupName -Description "Grupo de acesso da aplicacao $SiteName"
    Write-Host "Grupo '$GroupName' criado."
} else {
    Write-Host "Grupo '$GroupName' ja existe."
}
 
try {
    Add-LocalGroupMember -Group $GroupName -Member $UserName -ErrorAction Stop
    Write-Host "Usuario '$UserName' adicionado ao grupo '$GroupName'."
} catch {
    Write-Host "Usuario ja e membro do grupo ou nao pode ser adicionado: $($_.Exception.Message)"
}
 
# ---------------------------------------------------------------------------
# 2. Application Pool rodando com o usuario especificado
# ---------------------------------------------------------------------------
if (-not (Test-Path "IIS:\AppPools\$AppPoolName")) {
    New-WebAppPool -Name $AppPoolName | Out-Null
    Write-Host "Application pool '$AppPoolName' criado."
}
 
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($UserPassword)
)
 
Set-ItemProperty "IIS:\AppPools\$AppPoolName" -Name processModel -Value @{
    identityType = "SpecificUser"
    userName     = $UserName
    password     = $PlainPassword
}
Write-Host "Application pool '$AppPoolName' configurado para rodar como '$UserName'."
 
# ---------------------------------------------------------------------------
# 3. Site no IIS
# ---------------------------------------------------------------------------
if (-not (Test-Path "IIS:\Sites\$SiteName")) {
    New-Item "IIS:\Sites\$SiteName" -PhysicalPath $SitePhysicalPath -Bindings @{
        protocol              = "http"
        bindingInformation    = "*:$($Port):$HostHeader"
    } | Out-Null
    Write-Host "Site '$SiteName' criado em '$SitePhysicalPath'."
} else {
    Write-Host "Site '$SiteName' ja existe."
}
 
# ---------------------------------------------------------------------------
# 4. Binding HTTPS (com certificado autoassinado, se nenhum thumbprint for passado)
# ---------------------------------------------------------------------------
if (-not $CertificateThumbprint) {
    $cert = New-SelfSignedCertificate -DnsName $HostHeader -CertStoreLocation "Cert:\LocalMachine\My"
    $CertificateThumbprint = $cert.Thumbprint
    Write-Host "Certificado autoassinado gerado para '$HostHeader' (thumbprint: $CertificateThumbprint)."
}
 
if (-not (Get-WebBinding -Name $SiteName -Protocol https -ErrorAction SilentlyContinue)) {
    New-WebBinding -Name $SiteName -Protocol https -Port $HttpsPort -HostHeader $HostHeader -SslFlags 1
    $binding = Get-WebBinding -Name $SiteName -Protocol https
    $binding.AddSslCertificate($CertificateThumbprint, "my")
    Write-Host "Binding HTTPS adicionado na porta $HttpsPort."
} else {
    Write-Host "Binding HTTPS ja existe para o site."
}
 
# ---------------------------------------------------------------------------
# 5. Caminho do arquivo de log do site
# ---------------------------------------------------------------------------
if (-not (Test-Path $LogFilePath)) {
    New-Item -ItemType Directory -Path $LogFilePath -Force | Out-Null
}
Set-ItemProperty "IIS:\Sites\$SiteName" -Name logFile.directory -Value $LogFilePath
Write-Host "Log do site '$SiteName' redirecionado para '$LogFilePath'."
 
# ---------------------------------------------------------------------------
# 6. Aplicacao (sub-app) no nivel inferior do site, usando o pool criado
# ---------------------------------------------------------------------------
if (-not (Test-Path $AppPhysicalPath)) {
    New-Item -ItemType Directory -Path $AppPhysicalPath -Force | Out-Null
}
 
if (-not (Get-WebApplication -Site $SiteName -Name $AppName -ErrorAction SilentlyContinue)) {
    New-WebApplication -Site $SiteName -Name $AppName -PhysicalPath $AppPhysicalPath -ApplicationPool $AppPoolName | Out-Null
    Write-Host "Aplicacao '$AppName' criada em '$SiteName/$AppName', usando o pool '$AppPoolName'."
} else {
    Write-Host "Aplicacao '$AppName' ja existe no site."
}
 
Write-Host "`nProvisionamento concluido."