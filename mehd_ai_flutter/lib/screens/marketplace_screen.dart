import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mehd_ai_flutter/core/constants.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<dynamic> _configs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/marketplace/leaderboard'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _configs = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _subscribe(String configId, String name) async {
    try {
      final response = await http.post(Uri.parse('${AppConstants.baseUrl}/marketplace/subscribe/$configId'));
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: MehdAiTheme.blue,
              content: Text("Subscribed to $name! Creator receives 20% revenue share.", style: MehdAiTheme.terminalStyle.copyWith(color: Colors.white)),
            ),
          );
        }
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('SOCIAL SIGNAL MARKETPLACE', style: MehdAiTheme.headingStyle.copyWith(letterSpacing: 2)),
        backgroundColor: MehdAiTheme.bgSecondary,
        iconTheme: const IconThemeData(color: MehdAiTheme.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: MehdAiTheme.borderColor, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MehdAiTheme.blue))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _configs.length,
              itemBuilder: (context, index) {
                final config = _configs[index];
                return _buildConfigCard(config, index + 1);
              },
            ),
    );
  }

  Widget _buildConfigCard(dynamic config, int rank) {
    final bool isAlpha = config['certified_alpha'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: MehdAiTheme.headingStyle.copyWith(color: rank <= 3 ? MehdAiTheme.blue : MehdAiTheme.textSecondary, fontSize: 24),
            ),
          ),
          const SizedBox(width: 20),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(config['name'], style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    if (isAlpha)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: MehdAiTheme.yellow.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: MehdAiTheme.yellow)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.workspace_premium, color: MehdAiTheme.yellow, size: 12),
                            const SizedBox(width: 4),
                            Text('CERTIFIED ALPHA', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.yellow, fontSize: 10)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Creator: ${config['creator']}', style: MehdAiTheme.labelStyle),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCol('Win Rate', '${config['win_rate']}%'),
                    _buildStatCol('Return vs Market', '+${config['return_vs_market']}%', color: MehdAiTheme.green),
                    _buildStatCol('Followers', '${config['followers']}'),
                  ],
                ),
              ],
            ),
          ),
          // Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${config['subscription_fee']}/mo', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MehdAiTheme.blue.withOpacity(0.1),
                  side: const BorderSide(color: MehdAiTheme.blue),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => _subscribe(config['id'], config['name']),
                child: Text('SUBSCRIBE TO SETUP', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(right: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MehdAiTheme.labelStyle.copyWith(fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: MehdAiTheme.terminalStyle.copyWith(color: color ?? MehdAiTheme.textPrimary, fontSize: 14)),
        ],
      ),
    );
  }
}
