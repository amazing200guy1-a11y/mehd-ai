const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

const THRESHOLDS = {
  "civilian": 0.70,
  "operative": 0.80,
  "sovereign": 0.95
};

// MOCK AGENT CALLS FOR NOW (Real API Keys should be injected via process.env in production)
const mockCall = async (symbol, name, layer) => {
  return {
    display_name: name,
    layer: layer,
    direction: Math.random() > 0.3 ? 'BUY' : 'HOLD', // Just a placeholder for actual AI prediction
    confidence: 85.0 + (Math.random() * 10),
    reasoning: `Analysis complete for ${symbol}.`
  };
};

const callDon = (symbol) => mockCall(symbol, "DON", "THE UNDERWORLD");
const callPhantom = (symbol) => mockCall(symbol, "PHANTOM", "THE UNDERWORLD");
const callOracle = (symbol) => mockCall(symbol, "ORACLE", "THE UNDERWORLD");
const callCaesar = (symbol) => mockCall(symbol, "CAESAR", "THE EMPIRE");
const callSage = (symbol) => mockCall(symbol, "SAGE", "THE EMPIRE");
const callGuardian = (symbol) => mockCall(symbol, "GUARDIAN", "THE EMPIRE");
const callTitan = (symbol) => mockCall(symbol, "TITAN", "OLYMPUS");
const callAtlas = (symbol) => mockCall(symbol, "ATLAS", "OLYMPUS");
const callForge = (symbol) => mockCall(symbol, "FORGE", "OLYMPUS");
const callTheDon = (symbol) => mockCall(symbol, "THE DON", "SUPREME");
const callSentinel = async (symbol) => {
  return {
    display_name: "SENTINEL",
    layer: "GUARDIAN",
    clear: true,
    confidence: 100.0,
    reasoning: "No paradox detected."
  };
};

function calculateConsensus(votes, threshold) {
  let counts = { 'BUY': 0, 'SELL': 0, 'HOLD': 0 };
  for (let v of votes) {
    if (v && v.direction) {
      counts[v.direction]++;
    }
  }
  let majorityDirection = 'HOLD';
  let maxCount = -1;
  for (let dir in counts) {
    if (counts[dir] > maxCount) {
      maxCount = counts[dir];
      majorityDirection = dir;
    }
  }
  
  // Exclude non-voting sentinel and theDon if they don't have standard directional votes, 
  // but since we mapped 11 total above, we compute based on 11.
  let score = (maxCount / 11) * 100.0;
  return {
    finalDirection: majorityDirection,
    score: score,
    consensusPercentage: score
  };
}

exports.orchestrateConsensus = functions.https.onCall(
  async (data, context) => {

    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Unauthorized');
    const { symbol, userId, tier } = data;
    const threshold = THRESHOLDS[tier] || 0.70;

    // All 11 agents fire in parallel — never sequential
    const [
      don, phantom, oracle,
      caesar, sage, guardian,
      titan, atlas, forge,
      theDon, sentinel
    ] = await Promise.allSettled([
      callDon(symbol),     callPhantom(symbol),
      callOracle(symbol),  callCaesar(symbol),
      callSage(symbol),    callGuardian(symbol),
      callTitan(symbol),   callAtlas(symbol),
      callForge(symbol),   callTheDon(symbol),
      callSentinel(symbol)
    ]);

    const rawVotes = [
      don, phantom, oracle, caesar, sage, guardian,
      titan, atlas, forge, theDon, sentinel
    ];

    const votes = rawVotes
      .filter(v => v.status === 'fulfilled')
      .map(v => v.value);

    // Total: 11 votes always
    const consensus = calculateConsensus(votes, threshold);
    const sentinelClear = sentinel.value?.clear === true;
    const chairmanScore = theDon.value?.confidence || 0;

    const proceed =
      (consensus.score / 100.0) >= threshold &&
      sentinelClear &&
      chairmanScore >= threshold * 100;

    const payload = {
        symbol: symbol, 
        proceed: proceed,
        timestamp: new Date().toISOString(),
        agent_count: 11,
        tier: tier,
        final_direction: consensus.finalDirection,
        consensus_percentage: consensus.consensusPercentage,
        rejection_reason: proceed ? null : "Conditions unmet for tier " + tier,
        votes: votes.map(v => ({
          model_name: v.display_name,
          layer: v.layer,
          snapshot_id: "CLOUD_GEN",
          direction: v.direction || 'HOLD',
          confidence: v.confidence,
          reasoning: v.reasoning || ''
        }))
    };

    // Push to Firebase in real time
    await admin.firestore()
      .collection('users').doc(userId)
      .collection('analyses').add(payload);

    // Feature from UPGRADE 1: Log to sovereign_signals if Sovereign Lock activates
    if (tier === 'sovereign' && proceed) {
        await admin.firestore().collection('sovereign_signals').add({
            symbol: symbol,
            confidence: chairmanScore,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            userId: userId,
            tier: tier
        });
    }

    // Feature from UPGRADE 4: Rejection feed if rejected
    if (!proceed) {
        await admin.firestore().collection('rejection_feed').add({
            symbol: symbol,
            direction: consensus.finalDirection,
            reason: payload.rejectionReason,
            consensusScore: consensus.consensusPercentage,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
    }

    return payload;
  }
);
