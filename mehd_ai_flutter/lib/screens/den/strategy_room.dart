import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/core/api_service.dart';
import 'package:mehd_ai_flutter/widgets/den_verdict_card.dart';
import 'package:mehd_ai_flutter/widgets/den_loading_widget.dart';
import 'package:mehd_ai_flutter/core/den_identity.dart';

/// FILE — strategy_room.dart
///
/// Build Debrief:
/// The Strategy Room houses the heavy analytical lifters: Caesar, Sage, and Guardian.
/// These agents look at price action, technical structure, and risk-reward ratios.

/// 
/// We place the powerful DenVerdictCard at the top here because Strategy
/// is the bridge between raw sentiment and exact mathematics.

class StrategyRoom extends StatefulWidget {
  final ConsensusResult? consensusResult;
  final bool isAnalyzing;
  final String? activeSymbol;

  const StrategyRoom({
    super.key,
    this.consensusResult,
    this.isAnalyzing = false,
    this.activeSymbol,
  });

  @override
  State<StrategyRoom> createState() => _StrategyRoomState();
}

class _StrategyRoomState extends State<StrategyRoom> {
  final ApiService _apiService = ApiService();
  String? _specializedResponse;
  bool _isLoadingSpecialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.activeSymbol != null) {
      _fetchSpecializedData();
    }
  }

  Future<void> _fetchSpecializedData() async {
    setState(() => _isLoadingSpecialized = true);
    final data = await _apiService.denStrategy("Strategic analysis for ${widget.activeSymbol}");
    if (mounted) {
      setState(() {
        _specializedResponse = data['response'];
        _isLoadingSpecialized = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAnalyzing) {
      return const Center(child: DenLoadingWidget(message: 'Formulating Predator Strategy...'));
    }

    if (widget.consensusResult == null && _specializedResponse == null) {
      return _buildEmptyState();
    }

    final strategyVotes = widget.consensusResult?.votes.where(
      (v) => ['caesar', 'sage', 'guardian'].contains(v.modelName.toLowerCase())
    ).toList() ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        if (widget.consensusResult != null) DenVerdictCard(consensus: widget.consensusResult!),
        _buildRoomHeader(),
        if (_isLoadingSpecialized)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: MehdAiTheme.blue)),
          )
        else if (_specializedResponse != null)
          _buildSpecializedCard(),
        const SizedBox(height: 24),
        if (strategyVotes.isEmpty && _specializedResponse == null)
          Center(
            child: Text('No Empire Agents Responded.', style: MehdAiTheme.labelStyle),
          )
        else
          ...strategyVotes.map((v) => _buildPredatorCard(v)),
      ],
    );
  }

  Widget _buildSpecializedCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MehdAiTheme.purple.withOpacity(0.05),
        border: Border.all(color: MehdAiTheme.purple.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: MehdAiTheme.purple, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'STRATEGIC DECREE', 
                  style: MehdAiTheme.headingStyle.copyWith(fontSize: 14, color: MehdAiTheme.purple),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _specializedResponse!,
            style: MehdAiTheme.labelStyle.copyWith(height: 1.5, color: MehdAiTheme.textPrimary),
            overflow: TextOverflow.ellipsis,
            maxLines: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree, color: MehdAiTheme.purple),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'TECHNICAL STRATEGY', 
                  style: MehdAiTheme.headingStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing market structure, liquidity zones, and risk topologies to determine the highest probability setup.',
            style: MehdAiTheme.labelStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPredatorCard(AIVote vote) {
    Color dirColor = MehdAiTheme.textSecondary;
    if (vote.direction == 'BUY') dirColor = MehdAiTheme.green;
    if (vote.direction == 'SELL') dirColor = MehdAiTheme.red;

    final identity = DenIdentity.getIdentity(vote.modelName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary.withOpacity(0.5),
        border: Border(left: BorderSide(color: dirColor, width: 3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Icon(identity.icon, color: MehdAiTheme.textPrimary, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        identity.displayName,
                        style: MehdAiTheme.headingStyle.copyWith(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: dirColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    vote.direction,
                    style: MehdAiTheme.terminalStyle.copyWith(
                      color: dirColor,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            vote.reasoning,
            style: MehdAiTheme.labelStyle.copyWith(height: 1.5, color: MehdAiTheme.textSecondary),
            overflow: TextOverflow.ellipsis,
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.track_changes_outlined,
            color: Color(0xFF1A1A1A),
            size: 36,
          ),
          const SizedBox(height: 14),
          const Text(
            'SELECT A MARKET',
            style: TextStyle(
              color: Color(0xFF58A6FF),
              fontSize: 12,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a symbol from\nMarkets Explorer.',
            style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 10,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
