#!/bin/sh

cp .env-sepolia .env
source .env

forge script script/Upgrade_010_011.s.sol:Upgrade_010_011 --rpc-url $RPC_URL -vvv --broadcast --verify
