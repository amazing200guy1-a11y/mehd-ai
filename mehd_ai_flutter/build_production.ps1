# ══════════════════════════════════════════════════════════════
#  Mehd AI — Secure Production Build Script
#  Run this instead of plain flutter build for production releases.
# ══════════════════════════════════════════════════════════════
#
#  What this does:
#  1. Enables code obfuscation (scrambles variable/function names)
#  2. Splits debug info to a separate folder (for crash symbolication)
#  3. Sets DEMO_MODE=false to ensure auth is enforced
#  4. Points to the production backend URL
#
#  Usage:
#    .\build_production.ps1 -platform web
#    .\build_production.ps1 -platform apk
#    .\build_production.ps1 -platform ios
# ══════════════════════════════════════════════════════════════

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("web", "apk", "appbundle", "ios", "windows")]
    [string]$platform
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   MEHD AI — PRODUCTION BUILD             ║" -ForegroundColor Cyan
Write-Host "║   Code Obfuscation: ENABLED              ║" -ForegroundColor Cyan
Write-Host "║   Demo Mode: DISABLED                    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean previous build artifacts
Write-Host "[1/4] Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
Write-Host "  Done." -ForegroundColor Green

# Step 2: Get dependencies
Write-Host "[2/4] Fetching dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "  Done." -ForegroundColor Green

# Step 3: Run Flutter analyze to catch issues before build
Write-Host "[3/4] Running static analysis..." -ForegroundColor Yellow
flutter analyze --no-fatal-infos
Write-Host "  Done." -ForegroundColor Green

# Step 4: Build with security flags
Write-Host "[4/4] Building $platform with security hardening..." -ForegroundColor Yellow

$backendUrl = "https://mehd-ai-backend.railway.app"  # UPDATE with your actual production URL

$commonArgs = @(
    "--release",
    "--dart-define=DEMO_MODE=false",
    "--dart-define=BACKEND_URL=$backendUrl"
)

if ($platform -eq "web") {
    flutter build web @commonArgs
} elseif ($platform -eq "apk") {
    # APK/Android: Enable obfuscation + split debug info
    flutter build apk @commonArgs `
        --obfuscate `
        --split-debug-info=build/debug-info
} elseif ($platform -eq "appbundle") {
    flutter build appbundle @commonArgs `
        --obfuscate `
        --split-debug-info=build/debug-info
} elseif ($platform -eq "ios") {
    flutter build ios @commonArgs `
        --obfuscate `
        --split-debug-info=build/debug-info
} elseif ($platform -eq "windows") {
    flutter build windows @commonArgs `
        --obfuscate `
        --split-debug-info=build/debug-info
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   BUILD COMPLETE — Security Hardened     ║" -ForegroundColor Green
Write-Host "║                                          ║" -ForegroundColor Green
Write-Host "║   Obfuscation: ACTIVE                    ║" -ForegroundColor Green
Write-Host "║   Demo Mode:   OFF                       ║" -ForegroundColor Green
Write-Host "║   Backend:     PRODUCTION                ║" -ForegroundColor Green
Write-Host "║                                          ║" -ForegroundColor Green
Write-Host "║   Debug symbols: build/debug-info/       ║" -ForegroundColor Green
Write-Host "║   (Keep these for crash reports)          ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
