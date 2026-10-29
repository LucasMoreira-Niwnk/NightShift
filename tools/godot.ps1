param(
    [ValidateSet('editor', 'run', 'check', 'test', 'prepare')]
    [string]$Mode = 'editor',
    [switch]$Offline
)
$ErrorActionPreference = 'Stop'
$workspaceDirectory = Split-Path $PSScriptRoot -Parent
function Update-CurrentBranch {
    if ($Offline) { Write-Host 'Modo offline: usando a versao local.'; return }
    if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) {
        Write-Warning 'Git indisponivel; usando a versao local.'
        return
    }
    $changes = & git -C $workspaceDirectory status --porcelain
    if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel consultar o repositorio Git.' }
    if ($changes) {
        Write-Warning 'Ha alteracoes locais. Atualizacao do Git pulada para preservar seu trabalho; usando a versao local.'
        return
    }
    $branchName = & git -C $workspaceDirectory branch --show-current
    if ($LASTEXITCODE -ne 0 -or -not $branchName) { throw 'Selecione uma branch antes de atualizar o projeto.' }
    $upstream = & git -C $workspaceDirectory for-each-ref '--format=%(upstream:short)' "refs/heads/$branchName"
    if ($LASTEXITCODE -ne 0 -or -not $upstream) {
        Write-Warning 'Branch sem upstream; usando a versao local.'
        return
    }
    Write-Host "Atualizando a branch atual a partir de $upstream..."
    $previousPrompt = $env:GIT_TERMINAL_PROMPT
    $previousInteractive = $env:GCM_INTERACTIVE
    try {
        $env:GIT_TERMINAL_PROMPT = '0'
        $env:GCM_INTERACTIVE = 'Never'
        & git -C $workspaceDirectory -c http.connectTimeout=10 -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=15 pull --ff-only
        if ($LASTEXITCODE -ne 0) {
            throw 'Nao foi possivel atualizar a branch. Resolva a conexao/divergencia ou use -Offline para jogar a versao local.'
        }
    } finally {
        $env:GIT_TERMINAL_PROMPT = $previousPrompt
        $env:GCM_INTERACTIVE = $previousInteractive
    }
}
if ($Mode -in @('run', 'prepare')) { Update-CurrentBranch }
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
function Prepare-Imports {
    Write-Host 'Verificando e atualizando o cache de importacao do Godot...'
    $lock = $null
    $process = $null
    $outputPath = Join-Path $localData 'launch-import.log'
    $errorPath = Join-Path $localData 'launch-import-errors.log'
    try {
        $lock = [System.IO.File]::Open((Join-Path $localData 'launch-import.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
        $process = Start-Process -FilePath $godotExecutable -ArgumentList @('--headless', '--editor', '--path', ('"' + $projectDirectory + '"'), '--', '--nightshift-prepare') -RedirectStandardOutput $outputPath -RedirectStandardError $errorPath -WindowStyle Hidden -PassThru
        $null = $process.Handle
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        while (-not $process.WaitForExit(1000)) {
            if ($timer.Elapsed.TotalSeconds -gt 180) {
                $process.Kill()
                throw 'A importacao excedeu 3 minutos. Consulte .local/launch-import-errors.log ou abra o editor.'
            }
        }
        $process.WaitForExit()
        $process.Refresh()
        $outputText = [System.IO.File]::ReadAllText($outputPath)
        # The editor can log stale-resource errors before repairing them. The
        # plugin's marker confirms the final state after the import scan.
        if ($process.ExitCode -ne 0 -or $outputText -notmatch 'NIGHTSHIFT_IMPORT_READY') {
            throw "Importacao nao concluida (codigo $($process.ExitCode)). Consulte $outputPath e $errorPath."
        }
        Write-Host 'Cache atualizado. Assets prontos.'
    } finally {
        if ($null -ne $process) {
            if (-not $process.HasExited) { $process.Kill() }
            $process.Dispose()
        }
        if ($null -ne $lock) { $lock.Dispose() }
    }
}
if ($Mode -in @('run', 'prepare', 'check', 'test')) { Prepare-Imports }
switch ($Mode) {
    'editor' { & $godotExecutable --path $projectDirectory --editor }
    'run' { & $godotExecutable --path $projectDirectory }
    'check' {
        foreach ($scriptFile in (Get-ChildItem -LiteralPath (Join-Path $projectDirectory 'scripts') -Filter '*.gd' -Recurse)) {
            # Use Godot's canonical resource path so class_name scripts are not
            # loaded a second time under a Windows absolute-path identity.
            $resourcePath = 'res://' + $scriptFile.FullName.Substring($projectDirectory.Length + 1).Replace('\', '/')
            & $godotExecutable --headless --path $projectDirectory --check-only --script $resourcePath
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        }
    }
    # Captures explicitly draw frames; background/minimized windows must not stall physics tests.
    'test' { & $godotExecutable --disable-render-loop --path $projectDirectory -- --smoke-test }
    'prepare' { exit 0 }
}
exit $LASTEXITCODE
