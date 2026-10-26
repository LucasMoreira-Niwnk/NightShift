param(
    [ValidateSet('editor', 'run', 'check', 'test')]
    [string]$Mode = 'editor'
)
$ErrorActionPreference = 'Stop'
$godotDirectory = 'C:\Users\hsaug\Downloads\Godot_v4.0-stable_win64.exe'
$godotExecutable = Join-Path $godotDirectory 'Godot_v4.0-stable_win64_console.exe'
if ($env:NIGHTSHIFT_GODOT) { $godotExecutable = $env:NIGHTSHIFT_GODOT }
if (-not (Test-Path -LiteralPath $godotExecutable -PathType Leaf)) {
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
