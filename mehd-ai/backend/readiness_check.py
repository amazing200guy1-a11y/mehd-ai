"""Quick readiness check — run with: python readiness_check.py"""
from dotenv import load_dotenv
load_dotenv()
import os

print("=" * 50)
print("MEHD AI — SYSTEM READINESS CHECK")
print("=" * 50)

# Test imports
try:
    import main
    print("[OK] All imports pass")
except Exception as e:
    print(f"[FAIL] Import error: {e}")

# Test broker gateway
try:
    from broker_gateway import broker_gateway
    mode = "LIVE" if broker_gateway.is_live else "PAPER"
    print(f"[OK] Broker Gateway: {mode}")
except Exception as e:
    print(f"[FAIL] Broker Gateway: {e}")

# Test risk kernel
try:
    from risk_engine import HardRiskKernel
    k = HardRiskKernel()
    print(f"[OK] Risk Kernel: balance=${k.account.balance:.2f}, drawdown={k.account.daily_drawdown_pct:.2f}%")
except Exception as e:
    print(f"[FAIL] Risk Kernel: {e}")

# Check keys
print("\n--- API KEY STATUS ---")
keys = {
    "GROQ_API_KEY": "AI Consensus (free at console.groq.com)",
    "GEMINI_API_KEY": "AI Consensus (free at aistudio.google.com)",
    "ANTHROPIC_API_KEY": "AI Consensus + SENTINEL",
    "OPENAI_API_KEY": "AI Consensus + Chairman",
    "TWELVEDATA_API_KEY": "Market Data (free at twelvedata.com)",
    "OANDA_API_KEY": "Broker Execution",
    "OANDA_ACCOUNT_ID": "Broker Account",
    "CAPSULE_SIGNING_SECRET": "Security (required)",
}

for key, desc in keys.items():
    val = os.getenv(key, "")
    status = "SET" if val else "EMPTY"
    icon = "[+]" if val else "[ ]"
    print(f"  {icon} {key}: {status} — {desc}")

print("\n--- VERDICT ---")
required_set = all(os.getenv(k) for k in ["CAPSULE_SIGNING_SECRET"])
if required_set:
    print("Server CAN boot. Add AI + broker keys to wake the engine.")
else:
    print("Server CANNOT boot. Missing required keys above.")
print("=" * 50)
