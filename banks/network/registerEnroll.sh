#!/bin/bash

function createOrganization() {
  ORG_NAME=$1
  CA_PORT=$2
  PEER_COUNT=$3
  ORG_HOME_PATH="${PWD}/organizations/peerOrganizations/${ORG_NAME}.example.com"

  infoln "Enrolling the CA admin for $ORG_NAME"
  mkdir -p organizations/peerOrganizations/${ORG_NAME}.example.com/

  export FABRIC_CA_CLIENT_HOME=${ORG_HOME_PATH}/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:${CA_PORT} --caname ca-${ORG_NAME} --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-'${CA_PORT}'-ca-'${ORG_NAME}'.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-'${CA_PORT}'-ca-'${ORG_NAME}'.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-'${CA_PORT}'-ca-'${ORG_NAME}'.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-'${CA_PORT}'-ca-'${ORG_NAME}'.pem
    OrganizationalUnitIdentifier: orderer' > ${ORG_HOME_PATH}/msp/config.yaml

  infoln "Registering user for $ORG_NAME"
  set -x
  fabric-ca-client register --caname ca-${ORG_NAME} --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  infoln "Registering the org admin for $ORG_NAME"
  set -x
  fabric-ca-client register --caname ca-${ORG_NAME} --id.name ${ORG_NAME}admin --id.secret ${ORG_NAME}adminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  for ((i=0; i<PEER_COUNT; i++))
  do
    PEER_NAME="peer$i"
    PEER_HOST="peer$i.${ORG_NAME}.example.com"

    infoln "Registering $PEER_NAME for $ORG_NAME"
    set -x
    fabric-ca-client register --caname ca-${ORG_NAME} --id.name $PEER_NAME --id.secret ${PEER_NAME}pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
    { set +x; } 2>/dev/null

    infoln "Generating the $PEER_NAME msp for $ORG_NAME"
    set -x
    fabric-ca-client enroll -u https://${PEER_NAME}:${PEER_NAME}pw@localhost:${CA_PORT} --caname ca-${ORG_NAME} -M ${ORG_HOME_PATH}/peers/${PEER_HOST}/msp --csr.hosts ${PEER_HOST} --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
    { set +x; } 2>/dev/null

    cp ${ORG_HOME_PATH}/msp/config.yaml ${ORG_HOME_PATH}/peers/${PEER_HOST}/msp/config.yaml

    infoln "Generating the $PEER_NAME-tls certificates for $ORG_NAME"
    set -x
    fabric-ca-client enroll -u https://${PEER_NAME}:${PEER_NAME}pw@localhost:${CA_PORT} --caname ca-${ORG_NAME} -M ${ORG_HOME_PATH}/peers/${PEER_HOST}/tls --enrollment.profile tls --csr.hosts ${PEER_HOST} --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
    { set +x; } 2>/dev/null

    cp ${ORG_HOME_PATH}/peers/${PEER_HOST}/tls/tlscacerts/* ${ORG_HOME_PATH}/peers/${PEER_HOST}/tls/ca.crt
    cp ${ORG_HOME_PATH}/peers/${PEER_HOST}/tls/signcerts/* ${ORG_HOME_PATH}/peers/${PEER_HOST}/tls/server.crt
    cp ${ORG_HOME_PATH}/peers/${PEER_HOST}/tls/keystore/* ${ORG_HOME_PATH}/peers/${PEER_HOST}/tls/server.key
  
    mkdir -p ${ORG_HOME_PATH}/msp/tlscacerts
    cp ${ORG_HOME_PATH}/peers/${PEER_HOST}/tls/tlscacerts/* ${ORG_HOME_PATH}/msp/tlscacerts/ca.crt

    mkdir -p ${ORG_HOME_PATH}/tlsca
    cp ${ORG_HOME_PATH}/peers/${PEER_HOST}/tls/tlscacerts/* ${ORG_HOME_PATH}/tlsca/tlsca.${ORG_NAME}.example.com-cert.pem

    mkdir -p ${ORG_HOME_PATH}/ca
    cp ${ORG_HOME_PATH}/peers/${PEER_HOST}/msp/cacerts/* ${ORG_HOME_PATH}/ca/ca.${ORG_NAME}.example.com-cert.pem
  done

  infoln "Generating the user msp for $ORG_NAME"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:${CA_PORT} --caname ca-${ORG_NAME} -M ${ORG_HOME_PATH}/users/User1@${ORG_NAME}.example.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${ORG_HOME_PATH}/msp/config.yaml ${ORG_HOME_PATH}/users/User1@${ORG_NAME}.example.com/msp/config.yaml

  infoln "Generating the org admin msp for $ORG_NAME"
  set -x
  fabric-ca-client enroll -u https://${ORG_NAME}admin:${ORG_NAME}adminpw@localhost:${CA_PORT} --caname ca-${ORG_NAME} -M ${ORG_HOME_PATH}/users/Admin@${ORG_NAME}.example.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${ORG_HOME_PATH}/msp/config.yaml ${ORG_HOME_PATH}/users/Admin@${ORG_NAME}.example.com/msp/config.yaml
}
