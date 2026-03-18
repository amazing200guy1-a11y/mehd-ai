import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/core/constants.dart';

/// FILE 5 — symbol_sidebar.dart
///
/// Build Debrief:
/// This is the left panel of our IDE-style layout. It purposefully mimics a code 
/// editor's file explorer. Instead of files, it lists trading pairs.
/// Grouping them by asset class (Forex, Commodities, Indices) makes it intuitive 
/// for a pro trader. The pulsing risk indicator at the bottom serves as a constant 
/// psychological reminder that the Hard Risk Kernel is active and guarding the account.

class SymbolSidebar extends StatelessWidget {
  final String activeSymbol;
  final Function(String) onSymbolSelected;

  const SymbolSidebar({
    super.key,
    required this.activeSymbol,
    required this.onSymbolSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: MehdAiTheme.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'MARKETS EXPLORER',
              style: MehdAiTheme.labelStyle.copyWith(
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionHeader('FOREX'),
                ...AppConstants.symbols.take(4).map((s) => _buildSymbolRow(s)),
                
                const SizedBox(height: 12),
                _buildSectionHeader('COMMODITIES'),
                ...AppConstants.symbols.skip(4).take(2).map((s) => _buildSymbolRow(s)),
                
                const SizedBox(height: 12),
                _buildSectionHeader('INDICES & CRYPTO'),
                ...AppConstants.symbols.skip(6).map((s) => _buildSymbolRow(s)),
              ],
            ),
          ),

          // Risk Kernel Status at bottom
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: MehdAiTheme.borderColor)),
            ),
            child: Row(
              children: [
                // Pulsing dot simulation
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: MehdAiTheme.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RISK KERNEL', style: MehdAiTheme.labelStyle.copyWith(fontSize: 10, color: MehdAiTheme.purple)),
                      Text('1% max active', style: MehdAiTheme.labelStyle.copyWith(fontSize: 11, color: MehdAiTheme.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.keyboard_arrow_down, size: 14, color: MehdAiTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            title,
            style: MehdAiTheme.labelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolRow(String symbol) {
    final isActive = symbol == activeSymbol;
    return InkWell(
      onTap: () => onSymbolSelected(symbol),
      child: Container(
        color: isActive ? MehdAiTheme.blue.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 6.0),
        child: Row(
          children: [
            Icon(
              Icons.show_chart,
              size: 14,
              color: isActive ? MehdAiTheme.blue : MehdAiTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              symbol,
              style: MehdAiTheme.terminalStyle.copyWith(
                color: isActive ? MehdAiTheme.blue : MehdAiTheme.textPrimary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
