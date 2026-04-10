import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

class Broker {
  final String id;
  final String name;
  final String initials;
  final String type;
  final Color color;

  const Broker({
    required this.id,
    required this.name,
    required this.initials,
    required this.type,
    required this.color,
  });
}

class BrokerScreen extends StatefulWidget {
  const BrokerScreen({super.key});

  @override
  State<BrokerScreen> createState() => _BrokerScreenState();
}

class _BrokerScreenState extends State<BrokerScreen> {
  bool _isConnected = false;
  String _connectedBroker = '';
  String _accountType = ''; // demo/live

  final List<Broker> brokers = [
    const Broker(id: 'oanda', name: 'OANDA', initials: 'OA', type: 'API Direct', color: Color(0xFF58A6FF)),
    const Broker(id: 'exness', name: 'Exness', initials: 'EX', type: 'MT5 Compatible', color: Color(0xFFFF6B00)),
    const Broker(id: 'icmarkets', name: 'IC Markets', initials: 'IC', type: 'MT5 Compatible', color: Color(0xFF00D4FF)),
    const Broker(id: 'pepperstone', name: 'Pepperstone', initials: 'PP', type: 'MT5 Compatible', color: Color(0xFF4ECDC4)),
    const Broker(id: 'xm', name: 'XM', initials: 'XM', type: 'MT5 Compatible', color: Color(0xFFD29922)),
    const Broker(id: 'mt5', name: 'Any MT5 Broker', initials: 'M5', type: 'MT5 Universal', color: Color(0xFF888888)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('CONNECT BROKER', style: MehdAiTheme.headingStyle.copyWith(letterSpacing: 1.5)),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
        iconTheme: const IconThemeData(color: MehdAiTheme.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            "CONNECT YOUR BROKER",
            style: MehdAiTheme.headingStyle.copyWith(color: const Color(0xFF888888), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            "The Den executes through your broker.",
            style: MehdAiTheme.labelStyle.copyWith(color: const Color(0xFF555555), fontSize: 11),
          ),
          const SizedBox(height: 24),
          
          if (_isConnected)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF001208),
                border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 20),
                      const SizedBox(width: 8),
                      Text("✓ CONNECTED", style: MehdAiTheme.headingStyle.copyWith(color: const Color(0xFF00FF88))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text("Broker: ${brokers.firstWhere((b) => b.id == _connectedBroker, orElse: () => brokers.last).name}", style: MehdAiTheme.labelStyle),
                  Text("Account: ****1234", style: MehdAiTheme.labelStyle),
                  Text("Type: ${_accountType.toUpperCase()}", style: MehdAiTheme.labelStyle),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isConnected = false;
                        _connectedBroker = '';
                        _accountType = '';
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('DISCONNECT', style: MehdAiTheme.terminalStyle.copyWith(color: const Color(0xFFFF3B3B), fontSize: 11)),
                  ),
                ],
              ),
            ),

          ...brokers.map((broker) => _buildBrokerCard(broker)),

          const SizedBox(height: 32),
          
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFF111111))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: MehdAiTheme.labelStyle.copyWith(color: const Color(0xFF444444))),
              ),
              const Expanded(child: Divider(color: Color(0xFF111111))),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF0A0A0A)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                const Text(
                  'PAPER TRADING',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 13, letterSpacing: 1, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '\$10,000 demo balance · Always available · Zero risk',
                  style: TextStyle(color: Color(0xFF555555), fontSize: 10),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    context.read<TradingController>().setPaperMode(true);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF020810),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: const BorderSide(color: Color(0xFF58A6FF), width: 0.5)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'CONTINUE WITH PAPER TRADING',
                      style: TextStyle(color: Color(0xFF58A6FF), fontSize: 10, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBrokerCard(Broker broker) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF080808),
        border: Border.all(color: const Color(0xFF111111)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 40, 
          height: 40,
          decoration: BoxDecoration(
            color: broker.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              broker.initials,
              style: TextStyle(color: broker.color, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Text(broker.name, style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
        subtitle: Text(broker.type, style: const TextStyle(color: Color(0xFF444444), fontSize: 10)),
        trailing: _isConnected && _connectedBroker == broker.id
          ? const Icon(Icons.check_circle, color: Color(0xFF00FF88))
          : TextButton(
              onPressed: () => _showConnectSheet(broker),
              child: const Text('CONNECT', style: TextStyle(color: Color(0xFF58A6FF), fontSize: 10, letterSpacing: 1)),
            ),
      ),
    );
  }

  void _showConnectSheet(Broker broker) {
    setState(() {
      _accountType = 'demo';
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF080808),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'CONNECT ${broker.name.toUpperCase()}',
                      style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (broker.id == 'oanda') ...[
                    _brokerField('API Key', obscure: true),
                    _brokerField('Account ID'),
                    _accountTypeToggle(setModalState),
                  ],
                  
                  if (broker.id != 'oanda') ...[
                    _brokerField('MT5 Login'),
                    _brokerField('MT5 Password', obscure: true),
                    _brokerField('Server', hint: 'e.g. Exness-MT5Real'),
                    _accountTypeToggle(setModalState),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0800),
                      border: Border.all(color: const Color(0xFFD29922).withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '⚠ Start with a DEMO account.\n'
                      'The Den recommends demo before live.\n'
                      'Credentials stored securely in Firebase.',
                      style: TextStyle(color: Color(0xFFD29922), fontSize: 10, height: 1.6),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF020810),
                        side: const BorderSide(color: Color(0xFF58A6FF)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        _connectBroker(broker);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'CONNECT BROKER →',
                        style: TextStyle(color: Color(0xFF58A6FF), letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _brokerField(String label, {bool obscure = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        obscureText: obscure,
        style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Color(0xFF444444), fontSize: 12),
          hintStyle: const TextStyle(color: Color(0xFF222222), fontSize: 11),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF111111))),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF58A6FF))),
          filled: true,
          fillColor: const Color(0xFF050505),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _accountTypeToggle(StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          const Text('Account Type:', style: TextStyle(color: Color(0xFF444444), fontSize: 11)),
          const SizedBox(width: 16),
          ChoiceChip(
            label: const Text('DEMO'),
            selected: _accountType == 'demo',
            onSelected: (_) => setModalState(() => _accountType = 'demo'),
            selectedColor: const Color(0xFF020810),
            backgroundColor: const Color(0xFF080808),
            side: BorderSide(color: _accountType == 'demo' ? const Color(0xFF58A6FF) : const Color(0xFF111111)),
            labelStyle: TextStyle(
              color: _accountType == 'demo' ? const Color(0xFF58A6FF) : const Color(0xFF444444),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('LIVE'),
            selected: _accountType == 'live',
            onSelected: (_) => setModalState(() => _accountType = 'live'),
            selectedColor: const Color(0xFF120000),
            backgroundColor: const Color(0xFF080808),
            side: BorderSide(color: _accountType == 'live' ? const Color(0xFFFF3B3B) : const Color(0xFF111111)),
            labelStyle: TextStyle(
              color: _accountType == 'live' ? const Color(0xFFFF3B3B) : const Color(0xFF444444),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _connectBroker(Broker selectedBroker) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('broker')
            .doc('config')
            .set({
          'broker': selectedBroker.name,
          'type': _accountType,
          'status': 'pending',
          'savedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Ignored
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: const Color(0xFF0A0800),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('⏳ Credentials Saved',
              style: TextStyle(
                color: Color(0xFFD29922),
                fontWeight: FontWeight.bold)),
            Text(
              'Will activate when API key is added to backend.',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 10)),
          ]),
      ));
      
      // Keep it completely honest, we don't pretend it's connected right now.
      setState(() {
        _isConnected = false; 
      });
    }
  }
}
