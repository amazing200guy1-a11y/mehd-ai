import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:mehd_ai_flutter/services/payment_service.dart';
import 'package:mehd_ai_flutter/core/api_service.dart';
import 'package:mehd_ai_flutter/widgets/weekly_scan_card.dart';
import 'package:mehd_ai_flutter/widgets/legal_warning_dialog.dart';
import 'package:mehd_ai_flutter/widgets/techno_card.dart';

class CommandTab extends StatefulWidget {
  const CommandTab({super.key});

  @override
  State<CommandTab> createState() => _CommandTabState();
}

class _CommandTabState extends State<CommandTab> {
  Map<String, dynamic>? _statusData;
  bool _isLoading = true;
  bool _isAssistMode = false;
  bool _isPredatorMode = false;
  bool _isApprovingSniper = false; // Debounce guard
  bool _isTogglingMode = false;   // Debounce guard
  bool _isTogglingPredator = false; // Debounce guard

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    if (!mounted) return;
    try {
      final api = ApiService();
      final data = await api.getCommandCenterStatus();
      final config = await api.getAutopilotConfig();
      
      if (!mounted) return;
      setState(() {
        if (data != null) {
          _statusData = data;
        } else {
          _statusData = {
            "system_status": "WAITING",
            "active_snipers": [],
            "system_events": [],
            "risk_overview": {
              "equity": 0.0,
              "daily_drawdown": 0.0,
              "open_positions": 0,
              "max_positions": 3,
            }
          };
        }
        
        if (config != null) {
          _isAssistMode = config['assist_mode'] ?? false;
          _isPredatorMode = config['predator_mode'] ?? false;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to fetch command center status: $e");
      // Always show the UI — never crash to a red error screen
      if (mounted) {
        setState(() {
        _statusData ??= {
          "system_status": "OFFLINE",
          "is_simulated": true,
          "active_snipers": [],
          "system_events": [
            {"message": "Backend offline — running in demo mode."},
            {"message": "Connect backend at port 8000 to enable live signals."},
          ],
          "risk_overview": {
            "equity": 10000.0,
            "daily_drawdown": 0.0,
            "open_positions": 0,
            "max_positions": 3,
          }
        };
        _isLoading = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: MehdAiTheme.blue));
    }

    // _statusData is always set now — either live or seed data

    final snipers = _statusData!['active_snipers'] as List;
    final events = _statusData!['system_events'] as List;
    final risk = _statusData!['risk_overview'] as Map<String, dynamic>;
    final isSimulated = _statusData!['is_simulated'] == true;
    final paymentService = Provider.of<PaymentService>(context);
    final tier = paymentService.currentTier.toLowerCase();

    return Material(
      color: MehdAiTheme.bgPrimary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        children: [

          // ── HONESTY LAYER: SIMULATED BADGE ──
          if (isSimulated)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TechnoCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                borderColor: MehdAiTheme.amber.withOpacity(0.3),
                child: Row(
                  children: [
                    const Icon(Icons.science, color: MehdAiTheme.amber, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "SIMULATED — NO LIVE TRADES",
                        style: MehdAiTheme.headingStyle.copyWith(fontSize: 12, color: MehdAiTheme.amber),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── SUBSCRIPTION STATUS ──
          Consumer<PaymentService>(
            builder: (context, payment, _) => _buildTierInfo(payment),
          ),
          const SizedBox(height: 20),

          // ── SUBSYSTEM HEALTH ──
          _buildSubsystemHealth(),
          const SizedBox(height: 20),

          // ── WEEKLY AI SCAN ──
          if (tier == 'observer')
            WeeklyScanCard(
              scanData: {
                'generated_at': DateTime.now().toIso8601String(),
                'results': [
                  {'symbol': 'EUR/USD', 'direction': 'SELL', 'confidence': 88.5},
                  {'symbol': 'GBP/JPY', 'direction': 'BUY', 'confidence': 82.1},
                  {'symbol': 'XAU/USD', 'direction': 'BUY', 'confidence': 91.0},
                ]
              },
              onDismiss: () {},
            ),

          // ── Section Header: ACTIVE SIGNALS
          _buildSectionHeader(Icons.radar, "Active signals", MehdAiTheme.blue),
          const SizedBox(height: 14),
          
          // Snipers List
          if (snipers.isEmpty)
            TechnoCard(
              padding: const EdgeInsets.all(24),
              child: const Center(
                child: Text("No active snipers. Waiting for signals...", 
                  style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
              ),
            )
          else
            ...snipers.map((s) => _buildSniperCard(s)),
            
          const SizedBox(height: 28),

          // ── Section Header: CONTROLS
          _buildSectionHeader(Icons.tune_rounded, "Mode settings", Colors.white38),
          const SizedBox(height: 14),
          _buildExecutionModeToggle(),
          const SizedBox(height: 14),
          _buildPredatorToggle(),
          const SizedBox(height: 14),
          _buildTigerModeToggle(paymentService),

          const SizedBox(height: 28),

          // ── Section Header: INTEL
          _buildSectionHeader(Icons.analytics_rounded, "Overview", Colors.white38),
          const SizedBox(height: 14),

          // Intelligence Panel & Risk Row — always stacked on mobile
          _buildIntelligencePanel(),
          const SizedBox(height: 14),
          _buildRiskSnapshot(risk),

          const SizedBox(height: 28),

          // ── Section Header: OPERATIONAL LOG
          _buildSectionHeader(Icons.list_alt_rounded, "Activity log", Colors.white38),
          const SizedBox(height: 14),
          _buildEventsFeed(events),
          const SizedBox(height: 100), // Bottom nav safe area
        ],
      ),
    );
  }

  Widget _buildSniperCard(Map<String, dynamic> sniper) {
    final status = sniper['status'];
    final symbol = sniper['symbol'] ?? '';
    final isGold = symbol.contains('XAU');

    Color statusColor = MehdAiTheme.yellow;
    if (status == 'TRIGGERED' || status == 'EXECUTED') statusColor = MehdAiTheme.blue;
    if (status == 'AWAITING APPROVAL') statusColor = MehdAiTheme.amber;
    if (status == 'CANCELLED') statusColor = MehdAiTheme.red;

    // ── RULE 3: XAU/USD must NOT use forex pip logic ──
    // Gold displays dollar distance; forex displays pip distance.
    final String distanceLabel;
    final String distanceValue;
    if (isGold) {
      final dollarDist = sniper['distance_dollars'] ?? sniper['distance_pips'] ?? 0;
      distanceLabel = "Distance";
      distanceValue = "\$$dollarDist";
    } else {
      distanceLabel = "Distance";
      distanceValue = "${sniper['distance_pips'] ?? 0} pips";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TechnoCard(
        padding: const EdgeInsets.all(16),
        borderColor: statusColor.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${sniper['symbol']} - ${sniper['direction']}", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: statusColor, size: 8),
                      const SizedBox(width: 6),
                      Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDataCol("Target", sniper['entry_target'].toString()),
                _buildDataCol("Live", sniper['current_price'].toString()),
                _buildDataCol(distanceLabel, distanceValue, color: statusColor),
              ],
            ),

            // ── ASSIST MODE: APPROVE BUTTON WITH SAFETY GUARDS ──
            if (status == 'AWAITING APPROVAL') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isApprovingSniper
                        ? Colors.grey
                        : MehdAiTheme.amber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  // ── DEBOUNCE: Disabled while in-flight ──
                  onPressed: _isApprovingSniper
                      ? null
                      : () => _confirmAndApprove(sniper),
                  child: _isApprovingSniper
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black54,
                          ),
                        )
                      : const Text(
                          'APPROVE EXECUTION',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before approving a sniper execution.
  /// Guards against accidental taps and provides stale-signal awareness.
  Future<void> _confirmAndApprove(Map<String, dynamic> sniper) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MehdAiTheme.surface(context),
        title: const Text('CONFIRM EXECUTION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Approve ${sniper['direction']} on ${sniper['symbol']} '
          'at target ${sniper['entry_target']}?\n\n'
          'This action cannot be undone.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: MehdAiTheme.amber),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRM STRIKE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isApprovingSniper = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Assist Approve endpoint not yet deployed. Backend required.'),
          backgroundColor: MehdAiTheme.amber,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint("[CommandTab] APPROVE failed | symbol=${sniper['symbol']} | error=$e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approval failed: $e'),
          backgroundColor: MehdAiTheme.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isApprovingSniper = false);
    }
  }

  Widget _buildDataCol(String label, String value, {Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildIntelligencePanel() {
    return TechnoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Engine status", style: MehdAiTheme.headingStyle.copyWith(fontSize: 13, color: Colors.white60)),
          const SizedBox(height: 16),
          _buildInfoRow("Pullback detection", "On", MehdAiTheme.green),
          _buildInfoRow("Breakout detection", "On", MehdAiTheme.blue),
          _buildInfoRow("Stale signal guard", "On", MehdAiTheme.green),
          if (_isPredatorMode)
            _buildInfoRow("Position sizing", "1.5× (Alpha Mode)", MehdAiTheme.red),
        ],
      ),
    );
  }

  Widget _buildRiskSnapshot(Map<String, dynamic> risk) {
    return TechnoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Risk status", style: MehdAiTheme.headingStyle.copyWith(fontSize: 13, color: Colors.white60)),
          const SizedBox(height: 16),
          _buildInfoRow("Account equity", "\$${risk['equity']}", Colors.white),
          _buildInfoRow("Daily drawdown", "${risk['daily_drawdown']}%", MehdAiTheme.red),
          _buildInfoRow("Open positions", "${risk['open_positions']} / ${risk['max_positions']}", Colors.white70),
        ],
      ),
    );
  }

  Widget _buildTierInfo(PaymentService payment) {
    final used = payment.analysesUsedToday;
    final total = payment.analysesPerDay;
    final tier = payment.currentTier.toUpperCase();
    
    return TechnoCard(
      padding: const EdgeInsets.all(16),
      borderColor: MehdAiTheme.blue.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SUBSCRIPTION: $tier", style: MehdAiTheme.headingStyle.copyWith(fontSize: 12, color: MehdAiTheme.blue)),
              if (payment.isOnTrial)
                const Text("FREE TRIAL", style: TextStyle(color: MehdAiTheme.gold, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow("Analyses Today", "$used / ${total >= 999 ? 'Unlimited' : total}", used >= total && total < 999 ? MehdAiTheme.red : MehdAiTheme.green),
          _buildInfoRow("Autopilot Access", total >= 50 ? "UNLOCKED" : "LOCKED (Precision Req.)", total >= 50 ? MehdAiTheme.green : MehdAiTheme.grey),
        ],
      ),
    );
  }

  Widget _buildSubsystemHealth() {
    final healthData = _statusData?['subsystem_health'] as Map<String, dynamic>?;
    if (healthData == null) {
      return const SizedBox.shrink(); // Graceful empty state — no fake data
    }
    
    final aggregate = healthData['aggregate_state'] ?? 'GREEN';
    final subsystems = healthData['subsystems'] as Map<String, dynamic>? ?? {};
    
    Color aggregateColor = const Color(0xFF3FB950); // GREEN
    String aggregateLabel = 'ALL SYSTEMS OPERATIONAL';
    if (aggregate == 'YELLOW') {
      aggregateColor = const Color(0xFFD29922);
      aggregateLabel = 'PARTIAL DEGRADATION';
    } else if (aggregate == 'RED') {
      aggregateColor = const Color(0xFFF85149);
      aggregateLabel = 'SYSTEMS IMPAIRED';
    }
    
    return TechnoCard(
      padding: const EdgeInsets.all(16),
      borderColor: aggregateColor.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: aggregateColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(aggregateLabel, style: TextStyle(
                color: aggregateColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              )),
            ],
          ),
          const SizedBox(height: 12),
          // Individual subsystem rows
          ...subsystems.entries.map((entry) {
            final name = entry.key;
            final info = entry.value as Map<String, dynamic>? ?? {};
            final state = info['state'] ?? 'RED';
            final detail = info['detail'] ?? '';
            
            Color dotColor;
            if (state == 'GREEN') {
              dotColor = const Color(0xFF3FB950);
            } else if (state == 'YELLOW') {
              dotColor = const Color(0xFFD29922);
            } else {
              dotColor = const Color(0xFFF85149);
            }
            
            // Clean display name
            final displayName = name.replaceAll('_', ' ').toUpperCase();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: Text(displayName, style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    )),
                  ),
                  Expanded(
                    child: Text(detail, style: TextStyle(
                      color: dotColor.withOpacity(0.8),
                      fontSize: 10,
                    ), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Reusable section header widget ──
  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color valColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: TextStyle(color: valColor, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEventsFeed(List events) {
    if (events.isEmpty) {
      return TechnoCard(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text(
            "No events yet. System is monitoring...",
            style: TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }
    return TechnoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: events.map((ev) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.circle, color: MehdAiTheme.blue.withOpacity(0.5), size: 8),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(ev['message'], style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExecutionModeToggle() {
    return TechnoCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      borderColor: Colors.white12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Execution mode", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  _isAssistMode
                    ? "Assisted — requires your approval to enter"
                    : "Autonomous — executes signals automatically",
                  style: TextStyle(
                    color: _isAssistMode ? Colors.white54 : MehdAiTheme.blue,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _isTogglingMode
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MehdAiTheme.blue),
                  )
                : Switch(
                    value: _isAssistMode,
                    activeColor: MehdAiTheme.blue,
                    activeTrackColor: MehdAiTheme.blue.withOpacity(0.3),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.white10,
                    onChanged: _handleAssistModeToggle,
                  ),
        ],
      ),
    );
  }

  Widget _buildTigerModeToggle(PaymentService payment) {
    final isTiger = payment.isTigerModeEnabled;
    return TechnoCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      borderColor: isTiger ? MehdAiTheme.gold.withOpacity(0.3) : Colors.white12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tiger Mode", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  isTiger
                    ? "High conviction — maximum position sizing"
                    : "Standard mode — protected capital",
                  style: TextStyle(
                    color: isTiger ? MehdAiTheme.gold : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isTiger,
            activeColor: MehdAiTheme.gold,
            activeTrackColor: MehdAiTheme.gold.withOpacity(0.25),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.white10,
            onChanged: (val) {
              payment.toggleTigerMode(val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(val ? "Tiger Mode enabled" : "Tiger Mode disabled"),
                  backgroundColor: val ? MehdAiTheme.gold : Colors.grey.shade700,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPredatorToggle() {
    return TechnoCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      borderColor: _isPredatorMode ? MehdAiTheme.red.withOpacity(0.3) : Colors.white12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Alpha Mode", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  _isPredatorMode
                    ? "High conviction — 1.5× position sizing"
                    : "Defensive — capital preservation priority",
                  style: TextStyle(
                    color: _isPredatorMode ? MehdAiTheme.red : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _isTogglingPredator
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MehdAiTheme.red),
                  )
                : Switch(
                    value: _isPredatorMode,
                    activeColor: MehdAiTheme.red,
                    activeTrackColor: MehdAiTheme.red.withOpacity(0.25),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.white10,
                    onChanged: _handlePredatorToggle,
                  ),
        ],
      ),
    );
  }

  Future<void> _handlePredatorToggle(bool newValue) async {
    if (newValue) {
      final agreed = await LegalWarningDialog.show(context);
      if (!agreed) return;
    }

    final previousValue = _isPredatorMode;

    setState(() {
      _isPredatorMode = newValue;
      _isTogglingPredator = true;
    });

    try {
      final api = ApiService();
      final config = await api.getAutopilotConfig() ?? {};
      config['predator_mode'] = newValue;
      
      final success = await api.saveAutopilotConfig(config);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newValue
                  ? '🔥 ALPHA PREDATOR ACTIVATED. Risk scaling enabled.'
                  : '🛡️ Defensive Mode engaged. Capital preservation active.',
            ),
            backgroundColor: newValue ? MehdAiTheme.red : MehdAiTheme.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception("Server rejected config");
      }
    } catch (e) {
      debugPrint("[CommandTab] Predator toggle FAILED | error=$e");
      if (mounted) {
        setState(() => _isPredatorMode = previousValue);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Predator sync failed: $e'),
            backgroundColor: MehdAiTheme.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingPredator = false);
    }
  }

  Future<void> _handleAssistModeToggle(bool newValue) async {
    if (!newValue) {
      // Turning Assist Mode OFF means turning Full Autopilot ON
      final agreed = await LegalWarningDialog.show(context);
      if (!agreed) return;
    } else {
      final agreed = await LegalWarningDialog.show(context);
      if (!agreed) return;
    }

    final previousValue = _isAssistMode;

    setState(() {
      _isAssistMode = newValue;
      _isTogglingMode = true;
    });

    try {
      final api = ApiService();
      final config = await api.getAutopilotConfig() ?? {};
      config['assist_mode'] = newValue;
      
      final success = await api.saveAutopilotConfig(config);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newValue
                    ? 'Assisted mode on — waiting for your approval before each trade.'
                    : 'Autonomous mode on — the system will execute signals automatically.',
              ),
              backgroundColor: MehdAiTheme.blue,
              duration: const Duration(seconds: 3),
            ),
          );
      } else {
        throw Exception("Server rejected config");
      }
    } catch (e) {
      debugPrint("[CommandTab] Assist toggle FAILED | error=$e");
      if (mounted) {
        setState(() => _isAssistMode = previousValue);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mode sync failed: $e'),
            backgroundColor: MehdAiTheme.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingMode = false);
    }
  }
}
