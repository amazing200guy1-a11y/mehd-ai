import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

class PostMortemResult {
  final String mistakeDna;
  final String analysis;
  final ConstitutionRule? suggestedRule;

  PostMortemResult({
    required this.mistakeDna,
    required this.analysis,
    this.suggestedRule,
  });

  factory PostMortemResult.fromJson(Map<String, dynamic> json) {
    return PostMortemResult(
      mistakeDna: json['mistake_dna'] ?? 'Undefined',
      analysis: json['analysis'] ?? 'No analysis provided.',
      suggestedRule: json['suggested_rule'] != null
          ? ConstitutionRule.fromJson(json['suggested_rule'])
          : null,
    );
  }
}

// Reuse the ConstitutionRule model here or import it if extracted
// For simplicity assuming it's imported or defined similarly:
class ConstitutionRule {
  final String name;
  final String description;
  final String ruleType;
  final double parameter;

  ConstitutionRule({
    required this.name,
    required this.description,
    required this.ruleType,
    required this.parameter,
  });

  factory ConstitutionRule.fromJson(Map<String, dynamic> json) {
    return ConstitutionRule(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ruleType: json['rule_type'] ?? '',
      parameter: (json['parameter'] ?? 0).toDouble(),
    );
  }
}

class MistakeDnaDialog extends StatelessWidget {
  final PostMortemResult result;
  final VoidCallback onAcceptRule;

  const MistakeDnaDialog({
    super.key,
    required this.result,
    required this.onAcceptRule,
  });

  @override
  Widget build(BuildContext context) {
    bool isWin = result.mistakeDna == 'Systematic Execution';
    Color tintColor = isWin ? MehdAiTheme.green : MehdAiTheme.red;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: MehdAiTheme.bgPrimary,
          border: Border.all(color: tintColor.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: tintColor.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(isWin ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: tintColor, size: 28),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    isWin ? 'SYSTEMATIC EXECUTION' : 'MISTAKE DNA ISOLATED',
                    style: MehdAiTheme.terminalStyle.copyWith(
                      color: tintColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // DNA Classification
            Text('CLASSIFICATION:', style: MehdAiTheme.labelStyle),
            const SizedBox(height: 4),
            Text(
              result.mistakeDna.toUpperCase(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),

            // Auditor Analysis
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MehdAiTheme.bgSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: tintColor, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THE AUDITOR', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.purple)),
                  const SizedBox(height: 8),
                  Text(
                    result.analysis,
                    style: MehdAiTheme.headingStyle.copyWith(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5,
                  ),
                ],
              ),
            ),

            // Proposed Constitution Rule
            if (result.suggestedRule != null) ...[
              const SizedBox(height: 24),
              Text('PROPOSED MANDATE:', style: MehdAiTheme.labelStyle),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: MehdAiTheme.gold.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                  color: MehdAiTheme.gold.withOpacity(0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.suggestedRule!.name.toUpperCase(),
                      style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.gold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.suggestedRule!.description,
                      style: MehdAiTheme.bodyStyle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isWin)
                  Flexible(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'DISMISS',
                        style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Flexible(
                  child: ElevatedButton(
                    onPressed: () {
                      if (result.suggestedRule != null) {
                        onAcceptRule();
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isWin ? MehdAiTheme.green : (result.suggestedRule != null ? MehdAiTheme.gold : MehdAiTheme.bgSecondary),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      isWin 
                        ? 'ACKNOWLEDGE' 
                        : (result.suggestedRule != null ? 'ENSHRINE RULE' : 'I UNDERSTAND'),
                      style: MehdAiTheme.terminalStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isWin || result.suggestedRule != null ? Colors.black : Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
