import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _faqData = [
    {
      'category': 'Getting Started',
      'items': [
        {
          'q': 'What is Mehd AI?',
          'a': 'Mehd AI is the world\'s first retail trading platform powered by an 11-agent Synthetic Institutional Intelligence system. It operates like a hedge fund in your browser, analyzing data logically rather than emotionally.',
          'related': ['What is The Den?', 'What are the 11 agents?']
        },
        {
          'q': 'What is The Den?',
          'a': 'The Den is the core AI engine comprising 11 specialized agents. When you analyze a symbol, The Den holds a secure boardroom meeting where all 11 agents argue the merits of the trade before returning a Consensus-Verified result.',
          'related': ['What is Mehd AI?', 'What is Atomic Consensus?']
        },
        {
          'q': 'What are the 11 agents?',
          'a': 'The platform utilizes 11 specific agents, broken into three layers: The Underworld (Data gatherers like The Prophecy and Detective), The Empire (Strategists like The Sniper and Math Room), and Olympus (Oversight/Risk like The Don and Sentinel).',
          'related': ['What is THE DON?', 'What is Math Layer Veto?']
        },
        {
          'q': 'How do I create an account?',
          'a': 'Account creation is handled through the login portal. Choose "Create one" and provide your email. Once registered, you will be placed into immediate Simulated Trading (Paper Trading) to prove your discipline.',
          'related': ['What is paper trading?', 'How do I connect MT5?']
        },
        {
          'q': 'What is paper trading?',
          'a': 'Paper trading simulates the live market with fake capital. Mehd AI requires all new users to successfully complete 10 disciplined paper trades following our risk protocols before unlocking live brokerage connections.',
          'related': ['How do I create an account?', 'What is the 1% rule?']
        },
      ]
    },
    {
      'category': 'The Den & Analysis',
      'items': [
        {
          'q': 'Why is my trade button locked?',
          'a': 'The trade button is secured by Atomic Consensus. It will only unlock if 7 or more out of the 11 AI agents vote to proceed with the trade. If consensus is not reached, the trade is blocked to protect your capital.',
          'related': ['What is Atomic Consensus?', 'Why does The Den sometimes say HOLD?']
        },
        {
          'q': 'What does SENTINEL mean?',
          'a': 'SENTINEL is our ultimate fail-safe AI layer. If market conditions become irrational or API data anomalies are detected, SENTINEL triggers a global freeze, halting all trading capabilities until the market stabilizes.',
          'related': ['What is the kill switch?', 'Why is my trade button locked?']
        },
        {
          'q': 'What is the Gray Zone?',
          'a': 'The Gray Zone represents low-probability market conditions. When neither long nor short setups offer a statistical edge, The Den reports a Gray Zone and advises waiting for clarity.',
          'related': ['Why does The Den sometimes say HOLD?']
        },
        {
          'q': 'What is Math Layer Veto?',
          'a': 'Even if the majority of agents agree on a trade, the Quantitative Math Agent holds absolute veto power. If the math (risk-to-reward ratio, spread, liquidity) does not make statistical sense, the Math Layer will veto and block the trade.',
          'related': ['What is Atomic Consensus?', 'What is the 1% rule?']
        },
        {
          'q': 'Why does The Den sometimes say HOLD?',
          'a': 'Unlike humans, The Den does not feel the need to always be in a position. If there is no distinct edge, the consensus will be HOLD. Remember: Capital is a seed, not a sacrifice.',
          'related': ['What is the Gray Zone?']
        },
        {
          'q': 'What is Atomic Consensus?',
          'a': 'Atomic Consensus is the requirement that 7 out of 11 AI agents must independently agree on the direction and viability of a trade before the execution button is enabled.',
          'related': ['Why is my trade button locked?']
        },
        {
          'q': 'What is THE DON?',
          'a': 'THE DON is the Chief Risk Executive agent sitting at the top of the Olympus oversight layer. THE DON has the final say on all executions and enforces the unbreakable 1% risk rule.',
          'related': ['What is the 1% rule?']
        },
      ]
    },
    {
      'category': 'Risk & Safety',
      'items': [
        {
          'q': 'What is the 1% rule?',
          'a': 'The 1% rule is our foundational risk parameter. The HardRiskKernel mathematically restricts your lot size so that no single trade can ever lose more than 1% of your total account equity.',
          'related': ['Why can\'t I trade above 1% risk?', 'What is the kill switch?']
        },
        {
          'q': 'What is the kill switch?',
          'a': 'The kill switch is an extreme safety mechanism. If you suffer three consecutive stop-loss hits or exhibit emotional "tilt" behavior in Vibe Trading, the kill switch locks your account for 24 hours to prevent revenge trading.',
          'related': ['What happens when kill switch activates?']
        },
        {
          'q': 'Can I change my risk percentage?',
          'a': 'No. The 1% risk maximum is hardcoded into the platform architecture. We are building disciplined institutional traders, not gamblers.',
          'related': ['What is the 1% rule?']
        },
        {
          'q': 'What happens when kill switch activates?',
          'a': 'All active positions remain open with their predefined strict stop-losses, but you are blocked from opening any new positions or adjusting active stop-losses downwards until the 24-hour cooldown expires.',
          'related': ['What is the kill switch?']
        },
        {
          'q': 'Why can\'t I trade above 1% risk?',
          'a': 'Institutional hedge funds rarely risk more than 0.5% per trade. Retail traders fail because they risk 5%, 10%, or 20%. Mehd AI physically prevents you from making this fatal error.',
          'related': ['What is the 1% rule?']
        },
      ]
    },
    {
      'category': 'Account & Broker',
      'items': [
        {
          'q': 'How do I connect MT5?',
          'a': 'After passing the 10-trade paper simulator, navigate to Settings > Broker Integrations. Enter your MT5 login, password, and server details. We securely encrypt this connection.',
          'related': ['How do I connect OANDA?', 'What is demo mode?']
        },
        {
          'q': 'How do I connect OANDA?',
          'a': 'OANDA integration requires a v20 API token. Generate this token in your OANDA dashboard and paste it into the Broker Integrations section in Mehd AI.',
          'related': ['How do I connect MT5?']
        },
        {
          'q': 'What is demo mode?',
          'a': 'Demo mode allows you to explore the Mehd AI interface without real data or a connected broker. It is useful for learning where buttons are located before trading.',
          'related': ['What is paper trading?']
        },
        {
          'q': 'How do I upgrade to Pro?',
          'a': 'Mehd AI Pro unlocks lower latency endpoints and additional agents. You can upgrade via the Enterprise Licensing screen by paying with crypto or a credit card.',
          'related': ['How do I cancel subscription?']
        },
        {
          'q': 'How do I cancel subscription?',
          'a': 'Navigate to Settings > Billing. Click "Manage Subscription" to instantly cancel or pause your plan. You will retain access until the end of your billing cycle.',
          'related': ['How do I upgrade to Pro?']
        },
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    // Filter data based on search
    List<Map<String, dynamic>> filteredData = [];
    if (_searchQuery.isEmpty) {
      filteredData = _faqData;
    } else {
      for (var category in _faqData) {
        final matchingItems = (category['items'] as List).where((item) {
          final q = item['q'].toString().toLowerCase();
          final a = item['a'].toString().toLowerCase();
          final sq = _searchQuery.toLowerCase();
          return q.contains(sq) || a.contains(sq);
        }).toList();

        if (matchingItems.isNotEmpty) {
          filteredData.add({
            'category': category['category'],
            'items': matchingItems,
          });
        }
      }
    }

    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Help Center: The Den FAQ', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: MehdAiTheme.borderColor, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: MehdAiTheme.bgSecondary,
              border: Border(bottom: BorderSide(color: MehdAiTheme.borderColor)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: MehdAiTheme.terminalStyle,
              decoration: InputDecoration(
                hintText: 'Search the knowledge base...',
                hintStyle: MehdAiTheme.labelStyle,
                prefixIcon: const Icon(Icons.search, color: MehdAiTheme.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: MehdAiTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF0D1117),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: MehdAiTheme.borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: MehdAiTheme.borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: MehdAiTheme.blue)),
              ),
            ),
          ),
          
          Expanded(
            child: filteredData.isEmpty
              ? Center(
                  child: Text('No answers found in The Den for "$_searchQuery".', style: MehdAiTheme.labelStyle),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final category = filteredData[index];
                    final items = category['items'] as List;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category['category'].toString().toUpperCase(),
                            style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 12),
                          ...items.map((item) => _buildFaqItem(item['q'], item['a'], item['related'] as List<String>)),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer, List<String> related) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22), // MehdAiTheme.bgSecondary darker
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: ExpansionTile(
        title: Text(question, style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        iconColor: MehdAiTheme.blue,
        collapsedIconColor: MehdAiTheme.textSecondary,
        childrenPadding: const EdgeInsets.all(20).copyWith(top: 0),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(answer, style: MehdAiTheme.labelStyle.copyWith(fontSize: 14, height: 1.6, color: MehdAiTheme.textSecondary)),
          const SizedBox(height: 16),
          const Divider(color: MehdAiTheme.borderColor),
          const SizedBox(height: 8),
          Text('RELATED ARTICLES', style: MehdAiTheme.labelStyle.copyWith(fontSize: 10, color: MehdAiTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: related.map((r) => InkWell(
              onTap: () {
                _searchController.text = r;
                setState(() => _searchQuery = r);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MehdAiTheme.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MehdAiTheme.blue.withOpacity(0.3)),
                ),
                child: Text(r, style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue, fontSize: 11)),
              ),
            )).toList(),
          )
        ],
      ),
    );
  }
}
