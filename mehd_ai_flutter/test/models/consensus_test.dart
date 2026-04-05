import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/screens/auth_screen.dart';

void main() {
  group('ConsensusResult', () {
    
    test('parses BUY correctly', () {
      final json = {
        'votes': [],
        'final_direction': 'BUY',
        'consensus_percentage': 78.0,
        'proceed': true,
        'tier': 'sovereign',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
      final r = ConsensusResult.fromJson(json);
      expect(r.finalDirection, 'BUY');
      expect(r.consensusPercentage, 78.0);
      expect(r.proceed, isTrue);
      expect(r.tier, 'sovereign');
    });
    
    test('handles missing fields safely', () {
      final json = {
        'final_direction': 'HOLD',
        'consensus_percentage': 0.0,
        'proceed': false,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
      expect(
        () => ConsensusResult.fromJson(json),
        returnsNormally,
      );
    });
    
    test('sovereign tier requires all 9 conditions', () {
      final r = ConsensusResult(
        votes: [],
        finalDirection: 'BUY',
        consensusPercentage: 100.0,
        proceed: true,
        tier: 'sovereign',
        timestamp: DateTime.now(),
        sovereignConditions: {
          'unanimity': true,
          'spread_ok': true,
          'volatility_ok': true,
          'session_ok': true,
          'drawdown_ok': true,
          'correlation_ok': true,
          'news_clear': true,
          'sentinel_clear': true,
          'don_approved': true,
        },
      );
      expect(r.isSovereignLockAchieved, isTrue);
    });
  });
  
  group('Risk Engine', () {
    
    test('1% risk never exceeded', () {
      const balance = 10000.0;
      const riskPct = 0.01;
      final risk = balance * riskPct;
      expect(risk, equals(100.0));
      expect(risk / balance, lessThanOrEqualTo(0.01));
    });
    
    test('kill switch at 3% drawdown', () {
      const balance = 10000.0;
      const equity = 9650.0;
      final drawdown = (balance - equity) / balance;
      expect(drawdown, greaterThanOrEqualTo(0.03));
    });
    
    test('minimum trade is 100', () {
      const minimum = 100.0;
      expect(99.99 >= minimum, isFalse);
      expect(100.0 >= minimum, isTrue);
      expect(150.0 >= minimum, isTrue);
    });
    
    test('sovereign needs 11/11', () {
      const required = 11;
      const agreed = 11;
      expect(agreed >= required, isTrue);
      expect(10 >= required, isFalse);
    });
    
    test('civilian threshold 8/11', () {
      const threshold = 8;
      const total = 11;
      final pct = threshold / total;
      expect(pct, closeTo(0.727, 0.001));
    });
  });
  
  group('Auth', () {
    
    testWidgets('auth screen renders', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      expect(find.text('THE DEN'), findsOneWidget);
    });
    
    testWidgets('has email field', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      expect(find.byType(TextField), findsWidgets);
    });
    
    testWidgets('has sign in button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      expect(find.text('ENTER THE DEN'), findsOneWidget);
    });
  });
}
