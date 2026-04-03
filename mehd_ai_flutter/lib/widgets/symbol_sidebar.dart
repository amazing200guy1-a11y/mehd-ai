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

class SymbolSidebar extends StatefulWidget {
  final String activeSymbol;
  final Function(String) onSymbolSelected;

  const SymbolSidebar({
    super.key,
    required this.activeSymbol,
    required this.onSymbolSelected,
  });

  @override
  State<SymbolSidebar> createState() => _SymbolSidebarState();
}

class _SymbolSidebarState extends State<SymbolSidebar> {
  final Map<String, double?> _alerts = {};

  void _showAlertDialog(String symbol) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MehdAiTheme.bgSecondary,
        title: Text('SET PRICE ALERT', style: MehdAiTheme.headingStyle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(symbol, style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: MehdAiTheme.terminalStyle,
              decoration: InputDecoration(
                labelText: 'Target Price',
                labelStyle: MehdAiTheme.labelStyle,
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: MehdAiTheme.borderColor)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: MehdAiTheme.blue)),
              ),
            ),
            if (_alerts[symbol] != null) ...[
              const SizedBox(height: 8),
              Text('Active alert: ${_alerts[symbol]!.toStringAsFixed(5)}', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.yellow)),
            ],
          ],
        ),
        actions: [
          if (_alerts[symbol] != null)
            TextButton(
              onPressed: () {
                setState(() => _alerts.remove(symbol));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(backgroundColor: MehdAiTheme.red, content: Text('Alert removed for $symbol', style: MehdAiTheme.terminalStyle)),
                );
              },
              child: Text('REMOVE', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final price = double.tryParse(controller.text);
              if (price != null) {
                setState(() => _alerts[symbol] = price);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(backgroundColor: MehdAiTheme.green, content: Text('Alert set for $symbol at ${price.toStringAsFixed(5)}', style: MehdAiTheme.terminalStyle)),
                );
              }
            },
            child: Text('SET ALERT', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.green)),
          ),
        ],
      ),
    );
  }

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
                      Text('RISK KERNEL', style: MehdAiTheme.labelStyle.copyWith(fontSize: 10, color: MehdAiTheme.purple), overflow: TextOverflow.ellipsis),
                      Text('1% max active', style: MehdAiTheme.labelStyle.copyWith(fontSize: 11, color: MehdAiTheme.textPrimary), overflow: TextOverflow.ellipsis),
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
          Expanded(
            child: Text(
              title,
              style: MehdAiTheme.labelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolRow(String symbol) {
    final isActive = symbol == widget.activeSymbol;
    final hasAlert = _alerts.containsKey(symbol);
    return InkWell(
      onTap: () => widget.onSymbolSelected(symbol),
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
            Expanded(
              child: Text(
                symbol,
                style: MehdAiTheme.terminalStyle.copyWith(
                  color: isActive ? MehdAiTheme.blue : MehdAiTheme.textPrimary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => _showAlertDialog(symbol),
              child: Icon(
                hasAlert ? Icons.notifications_active : Icons.notifications_none,
                size: 14,
                color: hasAlert ? MehdAiTheme.yellow : (isActive ? MehdAiTheme.blue.withOpacity(0.5) : MehdAiTheme.textSecondary.withOpacity(0.3)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
