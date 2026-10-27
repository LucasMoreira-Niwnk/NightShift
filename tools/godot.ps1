param(
    [ValidateSet('editor', 'run', 'check', 'test')]
    [string]$Mode = 'editor'
)
$ErrorActionPreference = 'Stop'

$godotExecutable = $null
$candidates = @(
    $env:NIGHTSHIFT_GODOT,
    (Join-Path $env:USERPROFILE 'Downloads\Godot_v4.0-stable_win64.exe\Godot_v4.0-stable_win64_console.exe'),
    (Join-Path $env:USERPROFILE 'Downloads\Godot_v4.0-stable_win64.exe\Godot_v4.0-stable_win64.exe'),
    'C:\Users\hsaug\Downloads\Godot_v4.0-stable_win64.exe\Godot_v4.0-stable_win64_console.exe'
)
foreach ($c in $candidates) {
    if ($c -and (Test-Path -LiteralPath $c -PathType Leaf)) {
        $godotExecutable = $c
        break
    }
}
if (-not $godotExecutable) {
    throw 'Godot não encontrado. Defina NIGHTSHIFT_GODOT com o caminho completo do executável.'
}

$projectDirectory = Join-Path (Split-Path $PSScriptRoot -Parent) 'game'
# Keep editor settings and runtime data local to this workspace.
$localData = Join-Path (Split-Path $PSScriptRoot -Parent) '.local'
$env:APPDATA = Join-Path $localData 'AppData'
$env:LOCALAPPDATA = Join-Path $localData 'LocalAppData'
New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
switch ($Mode) {
    'editor' { & $godotExecutable --path $projectDirectory --editor }
    'run' { & $godotExecutable --path $projectDirectory }
    'check' {
        foreach ($scriptFile in (Get-ChildItem -LiteralPath (Join-Path $projectDirectory 'scripts') -Filter '*.gd' -Recurse)) {
            & $godotExecutable --headless --path $projectDirectory --check-only --script $scriptFile.FullName
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        }
    }
    'test' { & $godotExecutable --path $projectDirectory -- --smoke-test }
}
exit $LASTEXITCODE
