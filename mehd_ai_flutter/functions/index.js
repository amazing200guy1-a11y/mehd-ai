const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const { orchestrateConsensus } = require("./consensus_orchestrator");

exports.orchestrateConsensus = orchestrateConsensus;
