# paper-fetcher Edge Launcher (v2.1 — primary CARSI browser, minimized)
# Edge (9225) is the PRIMARY browser for ALL paywalled publishers.
# Chrome CDP (9223) is fallback only. Chrome (9224) is Scholar-only.

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

try {
  $null = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/json/version" -UseBasicParsing -TimeoutSec 3
  Write-Host "Edge already running on port $Port." -ForegroundColor Green
  exit 0
} catch {}

$profile = Join-Path $env:LOCALAPPDATA "CodexLitProfiles\$ProfileName"
New-Item -ItemType Directory -Force $profile | Out-Null

Write-Host "Starting Edge (minimized)..." -ForegroundColor Cyan
Write-Host "  Port: $Port" -ForegroundColor Gray
Write-Host "  Profile: $profile" -ForegroundColor Gray
Write-Host ""
Write-Host "CARSI login — do all of these in THIS Edge window:" -ForegroundColor Yellow
Write-Host "  sciencedirect.com -> Sign in via institution -> SJTU" -ForegroundColor White
Write-Host "  onlinelibrary.wiley.com -> Institutional Login -> SJTU" -ForegroundColor White
Write-Host "  nature.com -> Login -> Institutional Login -> SJTU" -ForegroundColor White
Write-Host "  pubs.acs.org -> Sign in via institution -> SJTU" -ForegroundColor White
Write-Host "  cell.com -> Sign in via institution -> SJTU" -ForegroundColor White
Write-Host "  link.springer.com -> Log in via institution -> SJTU" -ForegroundColor White
Write-Host "  pubs.rsc.org -> Log in via institution -> SJTU" -ForegroundColor White
Write-Host ""
Write-Host "Leave this Edge window OPEN (you can minimize it)." -ForegroundColor Gray
Write-Host ""

# Start minimized — bring to front only for CARSI login
Start-Process -FilePath $edge -ArgumentList @(
  "--remote-debugging-port=$Port",
  "--user-data-dir=$profile",
  "--no-first-run",
  "--new-window",
  "https://www.sciencedirect.com"
) -WindowStyle Minimized

Write-Host "Edge launched (minimized). Waiting for CDP..." -ForegroundColor Cyan
for ($i = 1; $i -le 30; $i++) {
  try {
    $null = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/json/version" -UseBasicParsing -TimeoutSec 2
    Write-Host "Edge CDP ready on port $Port." -ForegroundColor Green
    exit 0
  } catch { Start-Sleep -Seconds 1 }
}
Write-Host "Edge started, CDP may need a moment." -ForegroundColor Yellow
