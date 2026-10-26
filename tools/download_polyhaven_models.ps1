$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$projectRoot = Split-Path $PSScriptRoot -Parent
$metadataRoot = Join-Path $projectRoot '.local\polyhaven-metadata'
New-Item -ItemType Directory -Force -Path $metadataRoot | Out-Null
$ids = 'SchoolChair_01','metal_office_desk','signal_flashlight','vintage_radio_transceiver','desk_lamp_arm_01','drawer_cabinet','binder_notebook'
foreach ($id in $ids) {
    $metadataPath = Join-Path $metadataRoot ($id + '.json')
    if (Test-Path -LiteralPath $metadataPath) {
        $files = Get-Content -LiteralPath $metadataPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } else {
        $files = Invoke-RestMethod -Uri ('https://api.polyhaven.com/files/' + $id)
        $files | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $metadataPath -Encoding utf8
    }
    $entry = $files.gltf.'1k'.gltf
    if (-not $entry) { Write-Output ($id + ': no 1K glTF; skipped.'); continue }
    $assetRoot = Join-Path $projectRoot ('game\assets\models\polyhaven\' + $id)
    New-Item -ItemType Directory -Force -Path $assetRoot | Out-Null
    $downloads = @(@{Path=($id + '_1k.gltf');Data=$entry})
    foreach ($property in $entry.include.PSObject.Properties) {
        $downloads += @{Path=$property.Name;Data=$property.Value}
    }
    foreach ($download in $downloads) {
        $uri = [Uri]$download.Data.url
        if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'dl.polyhaven.org') { throw 'Unexpected asset host.' }
        $target = [IO.Path]::GetFullPath((Join-Path $assetRoot $download.Path))
        if (-not $target.StartsWith($assetRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid asset path.' }
        New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
        if (-not (Test-Path -LiteralPath $target)) { Invoke-WebRequest -Uri $uri -OutFile $target }
        $checksum = (Get-FileHash -LiteralPath $target -Algorithm MD5).Hash
        if ($checksum -ne $download.Data.md5) { throw ('Checksum mismatch: ' + $target) }
    }
    Write-Output ($id + ': downloaded and checksum verified.')
}
