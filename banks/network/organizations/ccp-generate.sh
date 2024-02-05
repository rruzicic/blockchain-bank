#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $7)
    local CP=$(one_line_pem $8)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${P1PORT}/$3/" \
        -e "s/\${P2PORT}/$4/" \
        -e "s/\${P3PORT}/$5/" \
        -e "s/\${CAPORT}/$6/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $7)
    local CP=$(one_line_pem $8)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${P1PORT}/$3/" \
        -e "s/\${P2PORT}/$4/" \
        -e "s/\${P3PORT}/$5/" \
        -e "s/\${CAPORT}/$6/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORG=1
P0PORT=1001
P1PORT=1002
P2PORT=1003
P3PORT=1004
CAPORT=1000
PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $P1PORT $P2PORT $P3PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1.json
echo "$(yaml_ccp $ORG $P0PORT $P1PORT $P2PORT $P3PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1.yaml

ORG=2
P0PORT=2001
P1PORT=2002
P2PORT=2003
P3PORT=2004
CAPORT=2000
PEERPEM=organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org2.example.com/ca/ca.org2.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $P1PORT $P2PORT $P3PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org2.example.com/connection-org2.json
echo "$(yaml_ccp $ORG $P0PORT $P1PORT $P2PORT $P3PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org2.example.com/connection-org2.yaml

ORG=3
P0PORT=3001
P1PORT=3002
P2PORT=3003
P3PORT=3004
CAPORT=3000
PEERPEM=organizations/peerOrganizations/org3.example.com/tlsca/tlsca.org3.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org3.example.com/ca/ca.org3.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $P1PORT $P2PORT $P3PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org3.example.com/connection-org3.json
echo "$(yaml_ccp $ORG $P0PORT $P1PORT $P2PORT $P3PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org3.example.com/connection-org3.yaml

ORG=4
P0PORT=4001
P1PORT=4002
P2PORT=4003
P3PORT=4004
CAPORT=4000
PEERPEM=organizations/peerOrganizations/org4.example.com/tlsca/tlsca.org4.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org4.example.com/ca/ca.org4.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $P1PORT $P2PORT $P3PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org4.example.com/connection-org4.json
echo "$(yaml_ccp $ORG $P0PORT $P1PORT $P2PORT $P3PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org4.example.com/connection-org4.yaml
