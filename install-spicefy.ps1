$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#region Variables
$spicetifyFolderPath = "$env:LOCALAPPDATA\spicetify"
$spicetifyOldFolderPath = "$HOME\spicetify-cli"
#endregion Variables

#region Functions
function Write-Success {
  param ()
  Write-Host ' > OK' -ForegroundColor Green
}

function Write-Unsuccess {
  param ()
  Write-Host ' > ERROR' -ForegroundColor Red
}

function Test-Admin {
  param ()
  Write-Host "Checking if the script is not being run as administrator..." -NoNewline
  $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  -not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-PowerShellVersion {
  param ()
  $PSMinVersion = [version]'5.1'
  Write-Host 'Checking if your PowerShell version is compatible...' -NoNewline
  $PSVersionTable.PSVersion -ge $PSMinVersion
}

function Move-OldSpicetifyFolder {
  param ()
  if (Test-Path $spicetifyOldFolderPath) {
    Write-Host 'Moving the old spicetify folder...' -NoNewline
    Copy-Item "$spicetifyOldFolderPath\*" $spicetifyFolderPath -Recurse -Force
    Remove-Item $spicetifyOldFolderPath -Recurse -Force
    Write-Success
  }
}

function Get-Spicetify {
  param ()
  if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') { $architecture = 'x64' }
  elseif ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { $architecture = 'arm64' }
  else { $architecture = 'x32' }

  Write-Host 'Fetching the latest spicetify version...' -NoNewline
  $latestRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/spicetify/cli/releases/latest'
  $targetVersion = $latestRelease.tag_name -replace 'v', ''
  Write-Success

  $archivePath = Join-Path ([System.IO.Path]::GetTempPath()) 'spicetify.zip'

  Write-Host "Downloading spicetify v$targetVersion..." -NoNewline
  Invoke-WebRequest -Uri "https://github.com/spicetify/cli/releases/download/v$targetVersion/spicetify-$targetVersion-windows-$architecture.zip" -OutFile $archivePath
  Write-Success

  return $archivePath
}

function Add-SpicetifyToPath {
  param ()
  Write-Host 'Making spicetify available in the PATH...' -NoNewline
  $user = [EnvironmentVariableTarget]::User
  $path = [Environment]::GetEnvironmentVariable('PATH', $user)
  $path = $path -replace "$([regex]::Escape($spicetifyOldFolderPath))\\*;*", ''
  if ($path -notlike "*$spicetifyFolderPath*") {
    $path += ";$spicetifyFolderPath"
  }
  [Environment]::SetEnvironmentVariable('PATH', $path, $user)
  $env:PATH = $path
  Write-Success
}

function Install-Spicetify {
  param ()
  Write-Host 'Installing spicetify...'
  $archivePath = Get-Spicetify
  Write-Host 'Extracting spicetify...' -NoNewline
  Expand-Archive -Path $archivePath -DestinationPath $spicetifyFolderPath -Force
  Write-Success
  Add-SpicetifyToPath

  Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
  Write-Host 'spicetify was successfully installed!' -ForegroundColor Green
}
#endregion Functions

#region Main
# Checks
if (-not (Test-PowerShellVersion)) {
  Write-Unsuccess
  Write-Warning 'PowerShell 5.1 or higher is required.'
  Pause
  exit
} else { Write-Success }

if (-not (Test-Admin)) {
  Write-Unsuccess
  Write-Warning "Do NOT run this script as admin."
  Pause
  exit
} else { Write-Success }

# Install Spicetify CLI
Move-OldSpicetifyFolder
Install-Spicetify

#endregion Main

#############################################################
#   AUTOMATISCHE MARKETPLACE INSTALLATIE (jouw versie)      #
#############################################################

Write-Host "`nStarting Marketplace setup..." -ForegroundColor Cyan

$spiceUserDataPath = "$env:APPDATA\spicetify"
$marketAppPath = "$spiceUserDataPath\CustomApps\marketplace"
$marketThemePath = "$spiceUserDataPath\Themes\marketplace"

# Verwijder oude folders
Remove-Item $marketAppPath, $marketThemePath -Recurse -Force -ErrorAction SilentlyContinue

# Nieuwe folders
New-Item $marketAppPath -ItemType Directory -Force | Out-Null
New-Item $marketThemePath -ItemType Directory -Force | Out-Null

$marketArchivePath = "$marketAppPath\marketplace.zip"
$unpackedFolderPath = "$marketAppPath\marketplace-dist"

# Download marketplace
Invoke-WebRequest -Uri 'https://github.com/spicetify/marketplace/releases/latest/download/marketplace.zip' -OutFile $marketArchivePath

# Uitpakken
Expand-Archive -Path $marketArchivePath -DestinationPath $marketAppPath -Force
Move-Item "$unpackedFolderPath\*" $marketAppPath -Force
Remove-Item $marketArchivePath, $unpackedFolderPath -Force

# Configure
spicetify config custom_apps spicetify-marketplace- -q
spicetify config custom_apps marketplace --bypass-admin
spicetify config inject_css 1 replace_colors 1

# Download theme
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/spicetify/marketplace/main/resources/color.ini' -OutFile "$marketThemePath\color.ini"

# Backup + Apply
spicetify backup --bypass-admin
spicetify config current_theme marketplace --bypass-admin
spicetify apply --bypass-admin

Write-Host "`nInstallation complete!" -ForegroundColor Green
