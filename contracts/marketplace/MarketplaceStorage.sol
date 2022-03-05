// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./MarketplaceStructs.sol";
import "../common/ownership/Ownable.sol";
import "../proxy/Initializable.sol";

contract MarketplaceStorage is Initializable, Ownable {
    MarketplaceConfig internal _config;

    mapping(address => bool) internal _eligibleForLootbox;
    mapping(address => uint256) internal _lootboxesBought;
    mapping(bytes32 => uint256) internal _salePrice;

    function __marketplaceStorageInit(MarketplaceConfig memory config, address owner) internal onlyInitializing {
        __ownableInit(owner);
        _config = config;
    }
}
