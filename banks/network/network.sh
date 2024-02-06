#!/bin/bash

CA_IMAGETAG="latest"
COMPOSE_FILE_CA=docker/docker-compose-ca.yaml
# use this as the default docker-compose yaml definition
COMPOSE_FILE_BASE=docker/docker-compose-fabric-net.yaml
# docker-compose.yaml file if you are using couchdb
COMPOSE_FILE_COUCH=docker/docker-compose-couch.yaml

CRYPTO="Certificate Authorities"

export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false

MAX_RETRY=5
# default for delay between commands
CLI_DELAY=3
# channel name defaults to "mychannel"
CHANNEL_NAME_1="channel1"
CHANNEL_NAME_2="channel2"

ORDERER_PORT_1=5001
ORDERER_PORT_2=6001

. scripts/utils.sh


function createOrgs() {
  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  if [ "$CRYPTO" == "cryptogen" ]; then
    # Create crypto material using cryptogen
    which cryptogen
    if [ "$?" -ne 0 ]; then
      fatalln "cryptogen tool not found. exiting"
    fi

    infoln "Generating certificates using cryptogen tool"

    infoln "Creating Org1 Identities"

    set -x
    cryptogen generate --config=./organizations/cryptogen/crypto-config-org1.yaml --output="organizations"
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi

    infoln "Creating Org2 Identities"

    set -x
    cryptogen generate --config=./organizations/cryptogen/crypto-config-org2.yaml --output="organizations"
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi

    infoln "Creating Org3 Identities"

    set -x
    cryptogen generate --config=./organizations/cryptogen/crypto-config-org3.yaml --output="organizations"
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi

    infoln "Creating Org4 Identities"

    set -x
    cryptogen generate --config=./organizations/cryptogen/crypto-config-org4.yaml --output="organizations"
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi

    infoln "Creating Orderer 1 Org Identities"

    set -x
    cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer1.yaml --output="organizations"
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi

    infoln "Creating Orderer 2 Org Identities"

    set -x
    cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer2.yaml --output="organizations"
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi
  fi

  # Create crypto material using Fabric CA
  if [ "$CRYPTO" == "Certificate Authorities" ]; then
    infoln "Generating certificates using Fabric CA"

    IMAGE_TAG=${CA_IMAGETAG} docker compose -f $COMPOSE_FILE_CA up -d 2>&1

    . registerEnroll.sh

  while :
    do
      if [ ! -f "organizations/fabric-ca/org1/tls-cert.pem" ]; then
        sleep 1
      else
        break
      fi
    done

    infoln "Creating Org1 Identities"

    createOrganization org1 1000 4 

    infoln "Creating Org2 Identities"

    createOrganization org2 2000 4 

    infoln "Creating Org3 Identities"

    createOrganization org3 3000 4 

    infoln "Creating Org4 Identities"

    createOrganization org4 4000 4 

    infoln "Creating Orderer 1 Org Identities"

    createOrderer orderer1 5000

    infoln "Creating Orderer 2 Org Identities"

    createOrderer orderer2 6000

  fi

  infoln "Generating CCP files for Orgs"
  ./organizations/ccp-generate.sh
}

function createConsortium() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    fatalln "configtxgen tool not found."
  fi

  infoln "Generating Orderer Genesis block"

  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  set -x
  configtxgen -profile FourOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    fatalln "Failed to generate orderer genesis block..."
  fi
}

function networkUp() {
  # checkPrereqs
  # generate artifacts if they don't exist
  if [ ! -d "organizations/peerOrganizations" ]; then
    createOrgs
    createConsortium
  fi

  COMPOSE_FILES="-f ${COMPOSE_FILE_BASE}"

  # if [ "${DATABASE}" == "couchdb" ]; then
  COMPOSE_FILES="${COMPOSE_FILES} -f ${COMPOSE_FILE_COUCH}"
  # fi

  IMAGE_TAG=$IMAGETAG docker compose ${COMPOSE_FILES} up -d 2>&1

  docker ps -a
  if [ $? -ne 0 ]; then
    fatalln "Unable to start network"
  fi
}

# call the script to create the channel, join the peers of org1 and org2, 
# and then update the anchor peers for each organization
function createChannel() {
  # Bring up the network if it is not already up.

  if [ ! -d "organizations/peerOrganizations" ]; then
    infoln "Bringing up network"
    networkUp
  fi

  # now run the script that creates a channel. This script uses configtxgen once
  # more to create the channel creation transaction and the anchor peer updates.
  # configtx.yaml is mounted in the cli container, which allows us to use it to
  # create the channel artifacts
  scripts/createChannel.sh $CHANNEL_NAME_1 $CLI_DELAY $MAX_RETRY $VERBOSE $ORDERER_PORT_1 1
  scripts/createChannel.sh $CHANNEL_NAME_2 $CLI_DELAY $MAX_RETRY $VERBOSE $ORDERER_PORT_2 2
}

## Call the script to deploy a chaincode to the channel
function deployCC() {
  scripts/deployCC.sh $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CC_SRC_LANGUAGE $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE

  if [ $? -ne 0 ]; then
    fatalln "Deploying chaincode failed"
  fi
}

## Parse mode
if [[ $# -lt 1 ]] ; then
  errorln "Not enough arguments provided"
  exit 0
else
  MODE=$1
  shift
fi

if [ "$MODE" == "up" ]; then
  networkUp
  createChannel
elif [ "$MODE" == "down" ]; then
  docker compose -f $COMPOSE_FILE_BASE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_CA down --volumes --remove-orphans
elif [ "$MODE" == "clean" ]; then
  rm -rf organizations/fabric-ca
  rm -rf organizations/ordererOrganizations
  rm -rf organizations/peerOrganizations
  rm -rf channel-artifacts
  rm -rf system-genesis-block
  rm -f log.txt
else
  errorln "Unknown mode"
fi
