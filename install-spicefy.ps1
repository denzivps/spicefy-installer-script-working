# ============================================
# install-spicefy.ps1
# Script om Spicetify + Marketplace te installeren en configureren
# ============================================

# 1. Installeer Spicetify CLI
iwr -useb https://raw.githubusercontent.com/spicetify/cli/main/install.ps1 | iex

# 2. Definieer paden
$spiceUserDataPath = "$env:APPDATA\spicetify"
$marketAppPath = "$spiceUserDataPath\CustomApps\marketplace"
$marketThemePath = "$spiceUserDataPath\Themes\marketplace"

# 3. Verwijder oude folders (indien aanwezig)
Remove-Item -Path $marketAppPath, $marketThemePath -Recurse -Force -ErrorAction 'SilentlyContinue'

# 4. Maak nieuwe folders
New-Item -Path $marketAppPath, $marketThemePath -ItemType Directory -Force | Out-Null

# 5. Download de Marketplace
$marketArchivePath = "$marketAppPath\marketplace.zip"
$unpackedFolderPath = "$marketAppPath\marketplace-dist"

Invoke-WebRequest -Uri 'https://github.com/spicetify/marketplace/releases/latest/download/marketplace.zip' -OutFile $marketArchivePath

# 6. Uitpakken en verplaatsen
Expand-Archive -Path $marketArchivePath -DestinationPath $marketAppPath -Force
Move-Item -Path "$unpackedFolderPath\*" -Destination $marketAppPath -Force

# 7. Opruimen
Remove-Item -Path $marketArchivePath, $unpackedFolderPath -Force

# 8. Configureer Spicetify Marketplace
spicetify config custom_apps spicetify-marketplace- -q
spicetify config custom_apps marketplace --bypass-admin
spicetify config inject_css 1 replace_colors 1 --bypass-admin

# 9. Download Marketplace kleurenthema
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/spicetify/marketplace/main/resources/color.ini' -OutFile "$marketThemePath\color.ini"

# 10. Backup maken en thema activeren
spicetify backup --bypass-admin
spicetify config current_theme marketplace --bypass-admin

# 11. Pas wijzigingen toe
spicetify apply --bypass-admin

Write-Host "`n✅ Spicetify en Marketplace zijn succesvol geïnstalleerd en geconfigureerd!" -ForegroundColor Green
