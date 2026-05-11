# paper-fetcher Chrome Launcher
# Start Chrome with remote debugging on port 9223, dedicated profile.
# Run once per session (or once after reboot). Chrome stays alive independently.
# All paper-fetcher operations reuse this Chrome instance.

param(
  [int]$Port = 9223,
  [string]$ProfileName = "paper-fetcher-chrome",
  [switch]$Scholar  # Use port 9224 + block third-party cookies for Google Scholar
)

if ($Scholar) {
  $Port = 9224
  $ProfileName = "scholar-search"
}

$ErrorActionPreference = "Stop"

# Find Chrome
function Get-ChromePath {
  $candidates = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe"
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
  )
  foreach ($path in $candidates) {
    if (Test-Path $path) { return $path }
  }
  throw "Chrome not found. Please install Google Chrome."
}

# Check if Chrome is already running on the target port
try {
  $response = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/json/version" -UseBasicParsing -TimeoutSec 3
  Write-Host "Chrome is already running on port $Port." -ForegroundColor Green
  Write-Host "Profile: $env:LOCALAPPDATA\CodexLitProfiles\$ProfileName" -ForegroundColor Gray
  Write-Host ""
  Write-Host "You can now use paper-fetcher. Chrome will stay running." -ForegroundColor Green
  exit 0
} catch {
  # Chrome not running — start it
}

$chrome = Get-ChromePath
$profile = Join-Path $env:LOCALAPPDATA "CodexLitProfiles\$ProfileName"
New-Item -ItemType Directory -Force $profile | Out-Null

Write-Host "Starting Chrome..." -ForegroundColor Cyan
Write-Host "  Port:    $Port" -ForegroundColor Gray
Write-Host "  Profile: $profile" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Log in to publisher sites in this Chrome window:" -ForegroundColor White
Write-Host "     - sciencedirect.com → Sign in → via your institution → CARSI → SJTU → jAccount" -ForegroundColor Gray
Write-Host "     - pubs.acs.org → Sign in → via your institution → SJTU" -ForegroundColor Gray
Write-Host "     - onlinelibrary.wiley.com → Sign in → Institutional Login → SJTU" -ForegroundColor Gray
Write-Host "  2. Leave this Chrome window open (you can minimize it)" -ForegroundColor White
Write-Host "  3. Login sessions persist in the profile — no need to re-login" -ForegroundColor White
Write-Host "  4. Paper-fetcher will automatically connect to this Chrome" -ForegroundColor White
Write-Host ""

$args = @(
  "--remote-debugging-port=$Port",
  "--user-data-dir=$profile",
  "--no-first-run",
  "--no-default-browser-check",
  "--disable-sync",
  "--disable-background-networking",
  "--remote-allow-origins=*"
)

if ($Scholar) {
  $args += "--block-third-party-cookies"
  $args += "https://scholar.google.com"
} else {
  $args += "https://www.sciencedirect.com"
}

Start-Process -FilePath $chrome -ArgumentList $args

Write-Host "Chrome launched. Waiting for CDP to be ready..." -ForegroundColor Cyan

$maxWait = 30
for ($i = 1; $i -le $maxWait; $i++) {
  try {
    $null = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/json/version" -UseBasicParsing -TimeoutSec 2
    Write-Host "CDP ready on port $Port." -ForegroundColor Green
    Write-Host ""
    Write-Host "Chrome is now running independently. You can close this terminal." -ForegroundColor Green
    exit 0
  } catch {
    Start-Sleep -Seconds 1
  }
}

Write-Host "Chrome started but CDP not responding yet. It should be ready soon." -ForegroundColor Yellow
Write-Host "Check: http://127.0.0.1:$Port/json/version" -ForegroundColor Gray
