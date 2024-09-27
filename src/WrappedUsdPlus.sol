// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {
    ERC4626Upgradeable,
    IERC20
} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {
    ERC20PermitUpgradeable,
    ERC20Upgradeable
} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {UsdPlus, ITransferRestrictor} from "./UsdPlus.sol";

/// @notice wrapped rebasing stablecoin
/// @author Dinari (https://github.com/dinaricrypto/usdplus-contracts/blob/main/src/WrappedUsdPlus.sol)
contract WrappedUsdPlus is UUPSUpgradeable, ERC4626Upgradeable, ERC20PermitUpgradeable, Ownable2StepUpgradeable {
    /// ------------------ Initialization ------------------

    function initialize(address usdplus, address initialOwner) public initializer {
        __ERC4626_init(IERC20(usdplus));
        __ERC20Permit_init("wUSD+");
        __ERC20_init("wUSD+", "wUSD+");
        __Ownable_init_unchained(initialOwner);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// ------------------ Getters ------------------

    function decimals() public view virtual override(ERC4626Upgradeable, ERC20Upgradeable) returns (uint8) {
        return ERC4626Upgradeable.decimals();
    }

    function _update(address from, address to, uint256 value) internal virtual override {
        // check if transfer is allowed
        UsdPlus(asset()).checkTransferRestricted(from, to);

        super._update(from, to, value);
    }

    function isBlacklisted(address account) external view returns (bool) {
        return UsdPlus(asset()).isBlacklisted(account);
    }
}
