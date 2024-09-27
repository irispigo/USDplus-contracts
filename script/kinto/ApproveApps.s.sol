// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {TransferRestrictor} from "../../src/TransferRestrictor.sol";
import {UsdPlus} from "../../src/UsdPlus.sol";
import {UsdPlusMinter} from "../../src/UsdPlusMinter.sol";
import {UsdPlusRedeemer} from "../../src/UsdPlusRedeemer.sol";
// import {AggregatorV3Interface} from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "../../src/mocks/ERC20Mock.sol";
import {IKintoWallet} from "kinto-contracts-helpers/interfaces/IKintoWallet.sol";
import {ISponsorPaymaster} from "kinto-contracts-helpers/interfaces/ISponsorPaymaster.sol";

import "kinto-contracts-helpers/EntryPointHelper.sol";

contract ApproveApps is Script, EntryPointHelper {
    function run() external {
        // load env variables
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address owner = vm.envAddress("KINTO_WALLET");
        address app = vm.envAddress("KINTO_APP");
        IEntryPoint _entryPoint = IEntryPoint(vm.envAddress("ENTRYPOINT"));
        ISponsorPaymaster _sponsorPaymaster = ISponsorPaymaster(vm.envAddress("SPONSOR_PAYMASTER"));

        console.log("deployer: %s", deployer);
        console.log("owner: %s", owner);

        // send txs as deployer
        vm.startBroadcast(deployerPrivateKey);

        // authorize kinto wallet to call contracts
        address[] memory apps = new address[](2);
        apps[0] = 0xB2eEc63Cdc175d6d07B8f69804C0Ab5F66aCC3cb;
        apps[1] = 0xF34f9C994E28254334C83AcE353d814E5fB90815;

        bool[] memory flags = new bool[](2);
        flags[0] = true;
        flags[1] = true;

        // for (uint256 i = 0; i < apps.length; i++) {
        //     uint256 _balance = _sponsorPaymaster.balances(apps[i]);
        //     if (_balance <= 0.0007 ether) {
        //         _sponsorPaymaster.addDepositFor{value: 0.0007 ether }(apps[i]);
        //         console.log("Adding paymaster balance to", apps[i]);
        //     }
        // }
        // Note: Fails due to SenderKYCRequired
        // _sponsorPaymaster.addDepositFor{value: 0.0007 ether}(owner);

        _handleOps(
            _entryPoint,
            abi.encodeWithSelector(IKintoWallet.whitelistApp.selector, apps, flags),
            owner,
            owner,
            address(_sponsorPaymaster),
            deployerPrivateKey
        );

        vm.stopBroadcast();
    }
}
