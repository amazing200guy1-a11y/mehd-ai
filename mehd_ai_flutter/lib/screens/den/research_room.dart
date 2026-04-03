import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/core/api_service.dart';
import 'package:mehd_ai_flutter/core/den_identity.dart';
import 'package:mehd_ai_flutter/widgets/den_loading_widget.dart';

/// FILE — research_room.dart
///
/// Build Debrief: 
/// The Research Room houses the web-connected sentiment models: 
/// Grok (Twitter/X live sentiment), Perplexity (Global News), and Gemini (Macro).
/// 
/// Why? 
/// Traders lose money ignoring fundamental news. These predators hunt the web 
/// for headlines, central bank drops, and social volume. Showing this explicitly 
/// reassures the user that macroeconomic risk is priced into The Den's verdict.

class ResearchRoom extends StatefulWidget {
  final ConsensusResult? consensusResult;
  final bool isAnalyzing;
  final String? activeSymbol;

  const ResearchRoom({
    super.key,
    this.consensusResult,
    this.isAnalyzing = false,
    this.activeSymbol,
  });

  @override
  State<ResearchRoom> createState() => _ResearchRoomState();
}

class _ResearchRoomState extends State<ResearchRoom> {
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
    final data = await _apiService.denResearch("Analyze sentiment for ${widget.activeSymbol}");
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
      return const Center(child: DenLoadingWidget(message: 'Scanning Global Sentiment...'));
    }

    if (widget.consensusResult == null && _specializedResponse == null) {
      return _buildEmptyState();
    }

    final researchVotes = widget.consensusResult?.votes.where(
      (v) => ['don', 'phantom', 'oracle'].contains(v.modelName.toLowerCase())
    ).toList() ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildRoomHeader(),
        if (_isLoadingSpecialized)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: MehdAiTheme.blue)),
          )
        else if (_specializedResponse != null)
          _buildSpecializedCard(),
        const SizedBox(height: 24),
        if (researchVotes.isEmpty && _specializedResponse == null)
          Center(
            child: Text('No Underworld Agents Responded.', style: MehdAiTheme.labelStyle),
          )
        else
          ...researchVotes.map((v) => _buildPredatorCard(v)),
      ],
    );
  }

  Widget _buildSpecializedCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MehdAiTheme.blue.withOpacity(0.05),
        border: Border.all(color: MehdAiTheme.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: MehdAiTheme.blue, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'DEN INTELLIGENCE', 
                  style: MehdAiTheme.headingStyle.copyWith(fontSize: 14, color: MehdAiTheme.blue),
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
              const Icon(Icons.travel_explore, color: MehdAiTheme.blue),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'FUNDAMENTAL SENTIMENT', 
                  style: MehdAiTheme.headingStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Scanning X (Twitter), Reuters, and global macro data to detect black swan events and shifted sentiment.',
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
