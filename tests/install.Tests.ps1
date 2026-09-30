$ErrorActionPreference = 'Stop'
$RepoDir = Split-Path -Parent $PSScriptRoot
. (Join-Path $RepoDir 'install-lib.ps1')

function Assert-True($condition, $message) {
    if (-not $condition) { throw $message }
}

$scratch = Join-Path ([IO.Path]::GetTempPath()) ("video-description-test-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $scratch | Out-Null
try {
    $content = '@echo off' + "`n" + 'bun run "C:\clone with spaces\index.ts" %*'
    Write-BatStub 'video-description' $content -ToolsDir $scratch
    $bat = Join-Path $scratch 'video-description.bat'
    Assert-True ((Get-Content $bat -Raw).Contains('"C:\clone with spaces\index.ts" %*')) 'Stub lost the quoted clone path or arguments.'
    $nonAscii = @([IO.File]::ReadAllBytes($bat) | Where-Object { $_ -gt 127 })
    Assert-True ($nonAscii.Count -eq 0) 'Batch launcher must be ASCII.'
    $icon = Join-Path $scratch 'video-description.ico'
    ConvertTo-Ico (Join-Path $RepoDir 'icons/video-description.png') $icon
    $bytes = [IO.File]::ReadAllBytes($icon)
    Assert-True ([BitConverter]::ToUInt16($bytes, 2) -eq 1) 'Invalid ICO type.'
    Assert-True ([BitConverter]::ToUInt32($bytes, 18) -eq 22) 'Incorrect PNG offset.'
    Assert-True ($bytes[22] -eq 137 -and $bytes[23] -eq 80) 'ICO does not contain PNG data.'
    $roots = @(Get-VideoDescriptionMenuRoots)
    Assert-True ($roots.Count -eq 16) 'Missing video, directory or background registration.'
    Assert-True ((Get-VideoDescriptionMenuCommand $roots[-1] 'C:\dev\tools') -eq 'cmd.exe /k ""C:\dev\tools\video-description.bat" "%V""') 'Background command must use %V.'
    Assert-True ((Get-VideoDescriptionMenuCommand $roots[0] 'C:\dev\tools') -eq 'cmd.exe /k ""C:\dev\tools\video-description.bat" "%1""') 'File command must use %1.'
} finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force
}

if ($env:OS -eq 'Windows_NT') {
    # Use an isolated registry key, never the user's real Explorer registrations.
    $root = 'HKCU:\Software\VideoDescriptionInstallerTest\' + [guid]::NewGuid()
    try {
        Set-MikesToolsRoot $root
        Add-MikesVerb $root 'OtherTool' 'Keep me' 'original.ico' 'original-command'
        Set-ItemProperty -LiteralPath $root -Name 'Icon' -Value 'shared.ico'
        Set-MikesToolsRoot $root
        Add-MikesVerb $root 'VideoDescription' 'Video Description' 'description.ico' 'first-command'
        Add-MikesVerb $root 'VideoDescription' 'Video Description' 'description.ico' 'updated-command'
        Assert-True ((Get-Item -LiteralPath "$root\shell\OtherTool\command").GetValue('') -eq 'original-command') 'Installing removed another tool.'
        Assert-True ((Get-ItemProperty -LiteralPath $root).Icon -eq 'shared.ico') 'Installing overwrote the shared icon.'
        Assert-True ((Get-Item -LiteralPath "$root\shell\VideoDescription\command").GetValue('') -eq 'updated-command') 'Reinstall did not update the command.'
    } finally {
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
    }
} else {
    Write-Host 'Skipped Windows registry tests on this platform.'
}
Write-Host 'Installer helper tests passed.' -ForegroundColor Green
