param(
    [switch]$SkipDeps,
    [string]$ToolsDir = 'C:\dev\tools'
)

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'install.ps1 requires Windows. On macOS use install.sh.' }
$RepoDir = $PSScriptRoot
. (Join-Path $RepoDir 'install-lib.ps1')

# Generated batch files are ASCII, so do not silently corrupt a Unicode clone path.
if ($RepoDir -match '[^\x00-\x7F]') { throw 'Clone into a path with ASCII characters for the Windows batch launcher.' }
if (-not $SkipDeps) { & (Join-Path $RepoDir 'deps.ps1') }
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
Write-BatStub 'video-description' @"
@echo off
bun run "$RepoDir\index.ts" %*
"@ -ToolsDir $ToolsDir

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
if (-not $userPath) { $userPath = '' }
if (-not $machinePath) { $machinePath = '' }
$onPath = (($userPath -split ';') + ($machinePath -split ';')) |
    Where-Object { $_.TrimEnd('\') -ieq $ToolsDir.TrimEnd('\') }
if (-not $onPath) {
    $answer = Read-Host "Add $ToolsDir to your User PATH? [Y/n]"
    if ($answer -eq '' -or $answer -imatch '^y') {
        [Environment]::SetEnvironmentVariable('Path', (($userPath.TrimEnd(';') + ";$ToolsDir").TrimStart(';')), 'User')
        $env:PATH += ";$ToolsDir"
        Write-Host 'Open a new terminal to use the updated PATH.' -ForegroundColor Yellow
    }
}

$iconsOut = Join-Path $env:LOCALAPPDATA 'video-description\icons'
New-Item -ItemType Directory -Path $iconsOut -Force | Out-Null
$icon = Join-Path $iconsOut 'video-description.ico'
ConvertTo-Ico (Join-Path $RepoDir 'icons\video-description.png') $icon
foreach ($root in Get-VideoDescriptionMenuRoots) {
    Set-MikesToolsRoot $root
    Add-MikesVerb $root 'VideoDescription' 'Video Description' $icon (Get-VideoDescriptionMenuCommand $root $ToolsDir)
}
Update-ExplorerMenus
Write-Host "Installed video-description from $RepoDir" -ForegroundColor Green
Write-Host 'Copy .env.example to .env here and set OPENROUTER_API_KEY before running.' -ForegroundColor Yellow
