import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('SECURITY PROMISE', style: TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Glowing shield header
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00FF88).withOpacity(0.05),
                  border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF88).withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.security, color: Color(0xFF00FF88), size: 42),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'THE SHIELD OF MEHD AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              
              const Text(
                'Built as a weapon against predatory broker cartels. Hardened to withstand any attempt to silence your edge.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF88A8D8),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Security guarantees
              _buildGuaranteeCard(
                icon: Icons.lock_outline,
                title: 'AES-256 KEY ENCRYPTION',
                description: 'Broker credentials are encrypted at-rest using hardware security keys (iOS Keychain / Android Keystore) and server-side master keys. Plain text keys are never stored.',
              ),
              const SizedBox(height: 16),
              
              _buildGuaranteeCard(
                icon: Icons.shield_outlined,
                title: 'ZERO-WITHDRAWAL POLICY',
                description: 'Mehd AI operates strictly in "Trade Only" mode. We never request, support, or require withdrawal or transfer capabilities. Your funds are physically untouchable by us.',
              ),
              const SizedBox(height: 16),
              
              _buildGuaranteeCard(
                icon: Icons.security_update_good_outlined,
                title: 'SSL CERTIFICATE PINNING',
                description: 'Connections are pinned directly to our server\'s cryptographic certificate. Any attempt to intercept traffic, hijack DNS, or execute middleman attacks is instantly blocked.',
              ),
              const SizedBox(height: 16),
              
              _buildGuaranteeCard(
                icon: Icons.gavel_outlined,
                title: 'FORENSIC AUDIT TRAILS',
                description: 'Every backend credential access and trade authorization is permanently logged. Insider threats or server tampering attempts are instantly traceable.',
              ),
              const SizedBox(height: 16),
              
              _buildGuaranteeCard(
                icon: Icons.speed_outlined,
                title: 'BOT SHIELD RATE LIMITS',
                description: 'Automated request sweeps and billing-abuse attacks are blocked at the gateway level. Your subscription API quotas are fully isolated and secure.',
              ),
              
              const SizedBox(height: 40),
              
              // Closing manifesto statement
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0D14),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '"Mehd AI is not just software. It is a tool for retail traders to reclaim control. Our security design ensures this power remains entirely yours and can never be weaponized against you by brokers or market manipulators."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6688AA),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuaranteeCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF020810).withOpacity(0.4),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00FF88), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
