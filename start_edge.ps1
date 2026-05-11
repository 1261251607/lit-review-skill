# paper-fetcher Edge Launcher for ScienceDirect
# Start Edge with remote debugging on port 9225, dedicated profile.
# Run once per session. Edge stays alive independently.

param(
  [int]$Port = 9225,
  [string]$ProfileName = "paper-fetcher-edge"
)

$ErrorActionPreference = "Stop"

$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edge)) {
  $edge = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
}
if (-not (Test-Path $edge)) {
  throw "Edge not found."
}

# Check if already running
try {
  $null = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/json/version" -UseBasicParsing -TimeoutSec 3
  Write-Host "Edge already running on port $Port." -ForegroundColor Green
  exit 0
} catch {}

$profile = Join-Path $env:LOCALAPPDATA "CodexLitProfiles\$ProfileName"
New-Item -ItemType Directory -Force $profile | Out-Null

Write-Host "Starting Edge for ScienceDirect..." -ForegroundColor Cyan
Write-Host "  Port: $Port" -ForegroundColor Gray
Write-Host "  Profile: $profile" -ForegroundColor Gray
Write-Host ""
Write-Host "Next:" -ForegroundColor Yellow
Write-Host "  1. Log into sciencedirect.com via CARSI" -ForegroundColor White
Write-Host "  2. Pass any bot verification page manually" -ForegroundColor White
Write-Host "  3. Click 'View PDF' on one article to confirm access" -ForegroundColor White
Write-Host "  4. Leave Edge open — paper-fetcher will reuse this session" -ForegroundColor White
Write-Host ""

Start-Process -FilePath $edge -ArgumentList @(
  "--remote-debugging-port=$Port",
  "--user-data-dir=$profile",
  "--no-first-run",
  "--new-window",
  "https://www.sciencedirect.com"
)

Write-Host "Edge launched. Waiting for CDP..." -ForegroundColor Cyan
for ($i = 1; $i -le 30; $i++) {
  try {
    $null = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/json/version" -UseBasicParsing -TimeoutSec 2
    Write-Host "Edge CDP ready on port $Port." -ForegroundColor Green
    exit 0
  } catch { Start-Sleep -Seconds 1 }
}
Write-Host "Edge started, CDP may need a moment." -ForegroundColor Yellow
