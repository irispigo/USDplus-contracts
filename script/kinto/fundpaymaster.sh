#!/bin/sh

cp .env-kinto-stage .env
source .env

forge script script/kinto/FundPaymaster.s.sol:FundPaymaster --rpc-url $RPC_URL -vvvv # --broadcast --skip-simulation
