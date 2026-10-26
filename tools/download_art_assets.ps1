$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$projectRoot = Split-Path $PSScriptRoot -Parent
$downloadDirectory = Join-Path $projectRoot '.local\art-downloads'
New-Item -ItemType Directory -Force -Path $downloadDirectory | Out-Null
$sources = @(
    @{ Name = 'Tiles074'; Url = 'https://ambientcg.com/get?file=Tiles074_1K-JPG.zip' },
    @{ Name = 'PaintedPlaster017'; Url = 'https://ambientcg.com/get?file=PaintedPlaster017_1K-JPG.zip' },
    @{ Name = 'Wood051'; Url = 'https://ambientcg.com/get?file=Wood051_1K-JPG.zip' },
    @{ Name = 'FurnitureKit'; Url = 'https://kenney.nl/media/pages/assets/furniture-kit/440e0608a4-1677580847/kenney_furniture-kit.zip' }
)
foreach ($source in $sources) {
    $archive = Join-Path $downloadDirectory ($source.Name + '.zip')
    if (-not (Test-Path -LiteralPath $archive)) {
        Invoke-WebRequest -Uri $source.Url -OutFile $archive
    }
    $destination = Join-Path $downloadDirectory $source.Name
    Expand-Archive -LiteralPath $archive -DestinationPath $destination -Force
    Write-Output ($source.Name + ' downloaded and extracted.')
}
