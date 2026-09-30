# deps.ps1 - install dependencies for video-description

if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
    throw "bun is not installed. Install it with: winget install oven-sh.bun"
}

Write-Host "  [bun]  Installing video-description dependencies..." -ForegroundColor DarkGray
Push-Location $PSScriptRoot
try {
    bun install --frozen-lockfile
    if ($LASTEXITCODE -ne 0) { throw "bun install failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}
Write-Host "  [ok]   video-description dependencies ready." -ForegroundColor Green
