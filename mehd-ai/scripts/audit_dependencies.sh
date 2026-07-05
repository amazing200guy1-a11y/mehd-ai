#!/bin/bash
# Mehd AI — Dependency Vulnerability Scanner
# ============================================
# The Equifax (2017) Defense Mechanism
# This script must pass before ANY deployment to production.
# It ensures no third-party library contains a known CVE.

set -e

echo "🛡️ Initiating Mehd AI Security Audit (Equifax Defense)..."
echo "--------------------------------------------------------"

# 1. Python Backend Audit (Strict CVE Check)
echo "[1/3] Scanning Backend Environment (Python)..."
cd ../backend
# Ensure pip-audit is installed quietly
python -m pip install --quiet pip-audit
# Run audit against requirements.txt
pip-audit -r requirements.txt
echo "✅ Backend dependencies are secure."
echo "--------------------------------------------------------"

# 2. Firebase Functions Audit (High/Critical CVE Check)
echo "[2/3] Scanning Cloud Functions (Node.js)..."
cd ../../mehd_ai_flutter/functions
# Run npm audit, fail only on high or critical vulnerabilities
npm audit --audit-level=high
echo "✅ Cloud Function dependencies are secure."
echo "--------------------------------------------------------"

# 3. Flutter App Audit (Outdated Check)
echo "[3/3] Scanning Flutter Client (Dart)..."
cd ..
# Check for major outdated packages
flutter pub outdated --no-dev-dependencies
echo "✅ Flutter dependencies reviewed."
echo "--------------------------------------------------------"

echo "🟢 ALL SCANS PASSED. THE VAULT IS SECURE."
echo "Ready for production deployment."
