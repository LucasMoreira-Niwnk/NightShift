param(
    [ValidateSet('editor', 'run', 'check', 'test')]
    [string]$Mode = 'editor'
)
$ErrorActionPreference = 'Stop'
$workspaceDirectory = Split-Path $PSScriptRoot -Parent
$godotExecutable = $env:NIGHTSHIFT_GODOT
$localConfig = Join-Path $workspaceDirectory '.local\godot-path.txt'
if (-not $godotExecutable -and (Test-Path -LiteralPath $localConfig -PathType Leaf)) {
    $godotExecutable = (Get-Content -LiteralPath $localConfig -Raw).Trim()
}
if (-not $godotExecutable) {
    $godotCommand = Get-Command godot -CommandType Application -ErrorAction SilentlyContinue
    if ($godotCommand) { $godotExecutable = $godotCommand.Source }
}
if (-not $godotExecutable) {
    # Preserve the existing portable installation, without tying it to a username.
    $godotExecutable = Join-Path $env:USERPROFILE 'Downloads\Godot_v4.0-stable_win64.exe\Godot_v4.0-stable_win64_console.exe'
}
if (-not (Test-Path -LiteralPath $godotExecutable -PathType Leaf)) {
    $fallbackGui = Join-Path $env:USERPROFILE 'Downloads\Godot_v4.0-stable_win64.exe\Godot_v4.0-stable_win64.exe'
    if (Test-Path -LiteralPath $fallbackGui -PathType Leaf) {
        $godotExecutable = $fallbackGui
    } else {
        throw 'Godot não encontrado. Defina NIGHTSHIFT_GODOT com o caminho completo do executável.'
    }
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
