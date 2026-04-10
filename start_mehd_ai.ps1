# MEHD AI — INSTANT LAUNCH SYSTEM
# ==============================
# This script starts the backend and frontend simultaneously 
# and opens the terminal in your browser.

Write-Host "MEHD AI: Initiating institutional boot sequence..." -ForegroundColor Cyan

# 1. Start Backend (The Den)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'c:\Mehd ai\mehd-ai\backend'; .\venv\Scripts\activate; uvicorn main:app --port 8000"
Write-Host "✓ Backend engine spinning up on port 8000" -ForegroundColor Green

# 2. Start Frontend (The Terminal)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'c:\Mehd ai\mehd_ai_flutter'; flutter run -d chrome --web-port 8080"
Write-Host "✓ Flutter terminal launching on port 8080" -ForegroundColor Green

# 3. Open Browser
Start-Sleep -Seconds 5
Start-Process "http://localhost:8080"
Write-Host "✓ Opening Mehd AI Terminal in browser..." -ForegroundColor Cyan

Write-Host "================================" -ForegroundColor Yellow
Write-Host "APP IS BOOTING — PLEASE WAIT..." -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow
