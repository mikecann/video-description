param([string]$ToolsDir = 'C:\dev\tools')

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'uninstall.ps1 requires Windows.' }
. (Join-Path $PSScriptRoot 'install-lib.ps1')

foreach ($root in Get-VideoDescriptionMenuRoots) {
    $verb = "$root\shell\VideoDescription"
    $commandKey = "$verb\command"
    if (Test-Path -LiteralPath $commandKey) {
        $command = (Get-Item -LiteralPath $commandKey).GetValue('')
        if ($command -eq (Get-VideoDescriptionMenuCommand $root $ToolsDir)) {
            Remove-Item -LiteralPath $verb -Recurse -Force
        }
    }
    # Never remove a shared Mike's Tools root, even if it is now empty.
}

$stub = Join-Path $ToolsDir 'video-description.bat'
if ((Test-Path -LiteralPath $stub) -and
    (Get-Content -LiteralPath $stub -Raw).Contains("bun run `"$PSScriptRoot\index.ts`" %*")) {
    Remove-Item -LiteralPath $stub -Force
    $bashStub = Join-Path $ToolsDir 'video-description'
    if (Test-Path -LiteralPath $bashStub) { Remove-Item -LiteralPath $bashStub -Force }
}
$icon = Join-Path $env:LOCALAPPDATA 'video-description\icons\video-description.ico'
if (Test-Path -LiteralPath $icon) { Remove-Item -LiteralPath $icon -Force }
Update-ExplorerMenus
Write-Host 'Removed video-description launchers and Explorer entries. Shared PATH and menus were kept.' -ForegroundColor Green
