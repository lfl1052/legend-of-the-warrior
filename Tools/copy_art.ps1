$ErrorActionPreference = 'Stop'
$srcImported = 'E:\U05277\Legend of the Warrior\Assets\ImportedArt'
$dstImported = 'E:\MyProject\GodotProject\Legend of the Warrior\art\imported'
$srcTextures = 'E:\U05277\Legend of the Warrior\Assets\Textures'
$dstTextures = 'E:\MyProject\GodotProject\Legend of the Warrior\art\textures'

if (-not (Test-Path $dstImported)) { New-Item -ItemType Directory -Path $dstImported -Force | Out-Null }
if (-not (Test-Path $dstTextures)) { New-Item -ItemType Directory -Path $dstTextures -Force | Out-Null }

Get-ChildItem $srcImported -Directory | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $dstImported -Recurse -Force
}
Get-ChildItem $srcTextures -File | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $dstTextures -Force
}

Get-ChildItem $dstImported -Recurse -Filter '*.meta' | Remove-Item -Force
Get-ChildItem $dstTextures -Recurse -Filter '*.meta' | Remove-Item -Force

$importedCount = (Get-ChildItem $dstImported -Recurse -File).Count
$texturesCount = (Get-ChildItem $dstTextures -Recurse -File).Count
Write-Host "IMPORTED_FILES=$importedCount"
Write-Host "TEXTURES_FILES=$texturesCount"
