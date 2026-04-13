import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/core/constitution_service.dart';

class ConstitutionScreen extends StatefulWidget {
  const ConstitutionScreen({super.key});

  @override
  State<ConstitutionScreen> createState() => _ConstitutionScreenState();
}

class _ConstitutionScreenState extends State<ConstitutionScreen> {
  final _service = ConstitutionService();
  AppConstitution? _constitution;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConstitution();
  }

  Future<void> _loadConstitution() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final constn = await _service.getConstitution();
      setState(() => _constitution = constn);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRuleParameter(ConstitutionRule rule, double newParam) async {
    if (_constitution == null) return;
    
    // Create new constitution with updated rule
    final updatedRules = _constitution!.rules.map((r) {
      if (r.id == rule.id) {
        return ConstitutionRule(
          id: r.id,
          name: r.name,
          description: r.description,
          ruleType: r.ruleType,
          parameter: newParam,
          isActive: r.isActive,
        );
      }
      return r;
    }).toList();

    final newConstitution = AppConstitution(
      rules: updatedRules,
      dailyTradesCount: _constitution!.dailyTradesCount,
      lastResetDate: _constitution!.lastResetDate,
    );

    setState(() => _isLoading = true);
    try {
      final saved = await _service.updateConstitution(newConstitution);
      setState(() => _constitution = saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e', style: MehdAiTheme.terminalStyle)),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('The Trader\'s Constitution', style: MehdAiTheme.headingStyle),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _constitution == null) {
      return const Center(child: CircularProgressIndicator(color: MehdAiTheme.blue));
    }
    if (_error != null) {
      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: MehdAiTheme.red, size: 64),
                const SizedBox(height: 16),
                Text(_error!, 
                  style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loadConstitution,
                  child: Text('RETRY', style: MehdAiTheme.terminalStyle),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (_constitution == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildHeaderAlert(),
        const SizedBox(height: 32),
        ..._constitution!.rules.map((rule) => _buildRuleCard(rule)),
      ],
    );
  }

  Widget _buildHeaderAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MehdAiTheme.red.withOpacity(0.1),
        border: Border.all(color: MehdAiTheme.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.admin_panel_settings, color: MehdAiTheme.red),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IMMUTABLE MANDATE',
                  style: MehdAiTheme.terminalStyle.copyWith(
                    color: MehdAiTheme.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'These rules are physically enforced by the Hard Risk Kernel. If a trade violates these parameters, the execution button will be disabled.',
                  style: MehdAiTheme.labelStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Trades taken today: ${_constitution!.dailyTradesCount}',
                  style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.textPrimary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(ConstitutionRule rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(rule.name.toUpperCase(), style: MehdAiTheme.headingStyle.copyWith(fontSize: 16)),
              Switch(
                value: rule.isActive,
                onChanged: (val) {
                  // Real feature would allow toggle here
                },
                activeColor: MehdAiTheme.blue,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(rule.description, style: MehdAiTheme.labelStyle),
          const SizedBox(height: 24),
          _buildParameterControl(rule),
        ],
      ),
    );
  }

  Widget _buildParameterControl(ConstitutionRule rule) {
    if (rule.ruleType == 'max_daily_trades') {
      return Row(
        children: [
          Text('Max Trades Limit: ', style: MehdAiTheme.labelStyle),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: MehdAiTheme.red),
            onPressed: () => _updateRuleParameter(rule, rule.parameter - 1),
          ),
          Text(rule.parameter.toInt().toString(), style: MehdAiTheme.terminalStyle.copyWith(fontSize: 20)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: MehdAiTheme.green),
            onPressed: () => _updateRuleParameter(rule, rule.parameter + 1),
          ),
        ],
      );
    }
    
    if (rule.ruleType == 'min_consensus') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Minimum Consensus: ${rule.parameter.toInt()}%', style: MehdAiTheme.labelStyle),
          Slider(
            value: rule.parameter,
            min: 50,
            max: 100,
            divisions: 10,
            activeColor: MehdAiTheme.blue,
            inactiveColor: MehdAiTheme.bgPrimary,
            onChanged: (val) => _updateRuleParameter(rule, val),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
