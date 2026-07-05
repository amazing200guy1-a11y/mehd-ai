# MEHD AI - INSTANT LAUNCH SYSTEM
# ==============================
# This script starts the backend and frontend simultaneously 
# and opens the terminal in your browser.

Write-Host "MEHD AI: Initiating institutional boot sequence..." -ForegroundColor Cyan

# 1. Start Backend (The Den)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'c:\Mehd ai\mehd-ai\backend'; .\venv\Scripts\activate; uvicorn main:app --port 8000"
Write-Host "[OK] Backend engine spinning up on port 8000" -ForegroundColor Green

# 2. Start Frontend (The Terminal)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'c:\Mehd ai\mehd_ai_flutter'; flutter run -d chrome --web-port 8080"
Write-Host "[OK] Flutter terminal launching on port 8080" -ForegroundColor Green

# 3. Start Landing Page (Marketing/Landing Page)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'c:\Mehd ai\landing'; & 'c:\Mehd ai\mehd-ai\backend\venv\Scripts\python.exe' -m http.server 5000"
Write-Host "[OK] Landing page server spinning up on port 5000" -ForegroundColor Green

# 4. Open Browser
Start-Sleep -Seconds 5
Start-Process "http://localhost:5000"
Start-Process "http://localhost:8080"
Write-Host "[OK] Opening Mehd AI Landing Page (port 5000) and Terminal (port 8080) in browser..." -ForegroundColor Cyan

Write-Host "======================================" -ForegroundColor Yellow
Write-Host "APP AND LANDING BOOTING - PLEASE WAIT..." -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow
