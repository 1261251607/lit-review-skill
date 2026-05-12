# paper-fetcher Chrome Launcher (v2.1 — minimized + Edge-first routing)
# Chrome CDP is now FALLBACK only. Edge (9225) is primary for all CARSI publishers.
# Scholar Chrome (9224) is for Google Scholar only (block third-party cookies).

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

try {
  $response = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/json/version" -UseBasicParsing -TimeoutSec 3
  Write-Host "Chrome is already running on port $Port." -ForegroundColor Green
  Write-Host "Profile: $env:LOCALAPPDATA\CodexLitProfiles\$ProfileName" -ForegroundColor Gray
  exit 0
} catch {}

$chrome = Get-ChromePath
$profile = Join-Path $env:LOCALAPPDATA "CodexLitProfiles\$ProfileName"
New-Item -ItemType Directory -Force $profile | Out-Null

Write-Host "Starting Chrome (minimized)..." -ForegroundColor Cyan
Write-Host "  Port:    $Port" -ForegroundColor Gray
Write-Host "  Profile: $profile" -ForegroundColor Gray

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
}

Start-Process -FilePath $chrome -ArgumentList $args -WindowStyle Minimized

Write-Host "Chrome launched (minimized). Waiting for CDP to be ready..." -ForegroundColor Cyan

$maxWait = 30
for ($i = 1; $i -le $maxWait; $i++) {
  try {
    $null = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/json/version" -UseBasicParsing -TimeoutSec 2
    Write-Host "CDP ready on port $Port." -ForegroundColor Green
    exit 0
  } catch {
    Start-Sleep -Seconds 1
  }
}

Write-Host "Chrome started but CDP not responding yet." -ForegroundColor Yellow
