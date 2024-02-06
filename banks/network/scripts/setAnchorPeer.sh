#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# import utils
. scripts/envVar.sh
. scripts/configUpdate.sh


# NOTE: this must be run in a CLI container since it requires jq and configtxlator 
createAnchorPeerUpdate() {
  infoln "Fetching channel config for channel $CHANNEL_NAME orderer $ORDERER_ID"
  fetchChannelConfig $ORG $CHANNEL_NAME ${CORE_PEER_LOCALMSPID}config$ORDERER_ID.json $ORDERER_ID

  infoln "Generating anchor peer update transaction for Org${ORG} on channel $CHANNEL_NAME"

  if [ $ORG -eq 1 ]; then
    HOST="peer0.org1.example.com"
    PORT=1001
  elif [ $ORG -eq 2 ]; then
    HOST="peer0.org2.example.com"
    PORT=2001
  elif [ $ORG -eq 3 ]; then
    HOST="peer0.org3.example.com"
    PORT=3001
  elif [ $ORG -eq 4 ]; then
    HOST="peer0.org4.example.com"
    PORT=4001
  else
    errorln "Org${ORG} unknown"
  fi

  set -x
  # Modify the configuration to append the anchor peer 
  jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${CORE_PEER_LOCALMSPID}config$ORDERER_ID.json > ${CORE_PEER_LOCALMSPID}modified_config$ORDERER_ID.json
  { set +x; } 2>/dev/null

  # Compute a config update, based on the differences between 
  # {orgmsp}config.json and {orgmsp}modified_config.json, write
  # it as a transaction to {orgmsp}anchors.tx
  createConfigUpdate ${CHANNEL_NAME} ${CORE_PEER_LOCALMSPID}config$ORDERER_ID.json ${CORE_PEER_LOCALMSPID}modified_config$ORDERER_ID.json ${CORE_PEER_LOCALMSPID}anchors$ORDERER_ID.tx
}

updateAnchorPeer() {
  if [ $ORDERER_ID -eq 1 ]; then
    ORDERER_PORT=5001
    ORDERER_CA=$ORDERER_1_CA
  elif [ $ORDERER_ID -eq 2 ]; then
    ORDERER_PORT=6001
    ORDERER_CA=$ORDERER_2_CA
  else
    errorln "Org${ORG} unknown"
  fi

  peer channel update -o orderer$ORDERER_ID.example.com:$ORDERER_PORT --ordererTLSHostnameOverride orderer$ORDERER_ID.example.com -c $CHANNEL_NAME -f ${CORE_PEER_LOCALMSPID}anchors$ORDERER_ID.tx --tls --cafile $ORDERER_CA >&log.txt
  res=$?
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  successln "Anchor peer set for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
}

ORG=$1
CHANNEL_NAME=$2
ORDERER_ID=$3
setGlobalsCLI $ORG

createAnchorPeerUpdate

updateAnchorPeer
