#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# imports
. scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true

export ORDERER_1_CA=${PWD}/organizations/ordererOrganizations/orderer1.example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export ORDERER_2_CA=${PWD}/organizations/ordererOrganizations/orderer2.example.com/orderers/orderer2.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG=${OVERRIDE_ORG}
  fi

  if [ $# -eq 2 ]; then
    PEER_PORT=${USING_ORG}00$((${2} + 1))
    PEER_CA=${PWD}/organizations/peerOrganizations/org${USING_ORG}.example.com/peers/peer${2}.org${USING_ORG}.example.com/tls/ca.crt
  else
    PEER_PORT=${USING_ORG}001
    PEER_CA=${PWD}/organizations/peerOrganizations/org${USING_ORG}.example.com/peers/peer0.org${USING_ORG}.example.com/tls/ca.crt
  fi
  
  infoln "Using organization ${USING_ORG} peer ${2}"
  if [ -n "$USING_ORG" ] && [ "$USING_ORG" -eq "$USING_ORG" ] 2>/dev/null; then
    export CORE_PEER_LOCALMSPID="Org${USING_ORG}MSP"
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org${USING_ORG}.example.com/users/Admin@org${USING_ORG}.example.com/msp
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER_CA
    export CORE_PEER_ADDRESS=localhost:${PEER_PORT}
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# Set environment variables for use in the CLI container 
setGlobalsCLI() {
  setGlobals $1 $2

  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi

  if [ $# -eq 2 ]; then
    PEER_PORT="${USING_ORG}00$((${2} + 1))"
  else
    PEER_PORT="${USING_ORG}001"
  fi  

  if [ -n "$USING_ORG" ] && [ "$USING_ORG" -eq "$USING_ORG" ] 2>/dev/null; then
    export CORE_PEER_ADDRESS=peer${2}.org${USING_ORG}.example.com:${PEER_PORT}
  else
    errorln "ORG Unknown"
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.org$1"
    ## Set peer addresses
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
    ## Set path to TLS certificate
    TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER0_ORG${1}_CA")
    PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    # shift by one to get to the next organization
    shift
  done
  # remove leading space for output
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
