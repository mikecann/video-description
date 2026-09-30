function Write-BatStub {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$ToolName,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [string]$ToolsDir
    )

    if (-not $PSBoundParameters.ContainsKey("ToolsDir")) {
        $ToolsDir = Get-Variable -Name ToolsDir -Scope 1 -ValueOnly
    }

    $batDest = Join-Path $ToolsDir "$ToolName.bat"
    Set-Content -Path $batDest -Value $Content -Encoding ASCII
    Write-Host "  [bat]  $batDest" -ForegroundColor Green

    $bashDest = Join-Path $ToolsDir $ToolName
    $bashContent = @'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/__TOOL_NAME__.bat" "$@"
'@.Replace("__TOOL_NAME__", $ToolName)
    Set-Content -Path $bashDest -Value $bashContent -Encoding ASCII
    Write-Host "  [bash] $bashDest" -ForegroundColor Green
}

# PNG-in-ICO preserves alpha transparency without System.Drawing.
function ConvertTo-Ico($pngPath, $icoPath) {
    $pngBytes = [System.IO.File]::ReadAllBytes($pngPath)
    $stream = [System.IO.FileStream]::new($icoPath, [System.IO.FileMode]::Create)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]1)
        $writer.Write([byte]16); $writer.Write([byte]16); $writer.Write([byte]0)
        $writer.Write([byte]0); $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$pngBytes.Length); $writer.Write([uint32]22)
        $writer.Write($pngBytes)
    } finally {
        $writer.Dispose()
        $stream.Dispose()
    }
}

function Set-MikesToolsRoot($rootKey) {
    # Keep any existing submenu (and its icon) owned by other tools.
    if (-not (Test-Path -LiteralPath $rootKey)) {
        New-Item -Path $rootKey -Force | Out-Null
        Set-ItemProperty -LiteralPath $rootKey -Name 'MUIVerb' -Value "Mike's Tools"
        Set-ItemProperty -LiteralPath $rootKey -Name 'SubCommands' -Value ''
        Set-ItemProperty -LiteralPath $rootKey -Name 'Icon' -Value "$env:SystemRoot\System32\shell32.dll,0"
    }
}

function Add-MikesVerb($rootKey, $verbName, $label, $icon, $command) {
    $verbKey = "$rootKey\shell\$verbName"
    $cmdKey = "$verbKey\command"
    if (-not (Test-Path -LiteralPath $cmdKey)) { New-Item -Path $cmdKey -Force | Out-Null }
    Set-ItemProperty -LiteralPath $verbKey -Name 'MUIVerb' -Value $label
    Set-ItemProperty -LiteralPath $verbKey -Name 'Icon' -Value $icon
    Set-ItemProperty -LiteralPath $cmdKey -Name '(Default)' -Value $command
}

function Get-VideoDescriptionMenuRoots {
    $videoExts = @('.mp4', '.mkv', '.avi', '.mov', '.wmv', '.webm', '.m4v', '.mpg', '.mpeg', '.ts', '.mts', '.m2ts', '.flv', '.f4v')
    foreach ($ext in $videoExts) {
        "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\MikesTools"
    }
    'HKCU:\Software\Classes\Directory\shell\MikesTools'
    'HKCU:\Software\Classes\Directory\Background\shell\MikesTools'
}

function Get-VideoDescriptionMenuCommand($rootKey, $ToolsDir) {
    $argument = if ($rootKey -like '*\Background\*') { '%V' } else { '%1' }
    return ('cmd.exe /k ""{0}\video-description.bat" "{1}""' -f $ToolsDir.TrimEnd('\'), $argument)
}

function Update-ExplorerMenus {
    if (-not ('VideoDescriptionShellNotify' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class VideoDescriptionShellNotify {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(int eventId, uint flags, IntPtr item1, IntPtr item2);
}
'@
    }
    [VideoDescriptionShellNotify]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
}
