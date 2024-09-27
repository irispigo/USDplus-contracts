// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {UsdPlus} from "../src/UsdPlus.sol";
import "../src/UsdPlusRedeemer.sol";
import {Permit} from "../src/SelfPermit.sol";

contract RedeemMulticall is Script {
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    function getPermitStructHash(Permit memory _permit) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(PERMIT_TYPEHASH, _permit.owner, _permit.spender, _permit.value, _permit.nonce, _permit.deadline)
        );
    }

    function getPermitTypedDataHash(bytes32 domainSeparator, Permit memory _permit) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, getPermitStructHash(_permit)));
    }

    function run() external {
        uint256 userPrivateKey = vm.envUint("USER_KEY");
        uint256 operatorPrivateKey = vm.envUint("OPERATOR_KEY");
        ERC20Permit usdc = ERC20Permit(vm.envAddress("USDC"));
        UsdPlus usdplus = UsdPlus(vm.envAddress("USDPLUS"));
        UsdPlusRedeemer redeemer = UsdPlusRedeemer(vm.envAddress("USDPLUS_REDEEMER"));

        uint256 amount = 10_000_000; // 10 USD+
        address user = vm.addr(userPrivateKey);
        address operator = vm.addr(operatorPrivateKey);

        console.log("user: %s", user);
        console.log("operator: %s", operator);

        // User sign USD+ permit
        vm.startBroadcast(userPrivateKey);

        Permit memory permit = Permit({
            owner: user,
            spender: address(redeemer),
            value: amount,
            nonce: usdplus.nonces(user),
            deadline: block.timestamp + 30 minutes
        });

        bytes32 digest = getPermitTypedDataHash(usdplus.DOMAIN_SEPARATOR(), permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        vm.stopBroadcast();

        // Operator pull USD+ and request redeem USD+ to USDC
        vm.startBroadcast(operatorPrivateKey);

        // Build multicall
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(
            redeemer.selfPermit, (address(usdplus), permit.owner, permit.value, permit.deadline, v, r, s)
        );
        calls[1] = abi.encodeCall(redeemer.requestRedeem, (usdc, amount, user, user));

        redeemer.multicall(calls);

        vm.stopBroadcast();
    }
}
