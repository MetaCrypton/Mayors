// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./MarketplaceStructs.sol";
import "../../common/ownership/OwnableStorage.sol";

contract MarketplaceStorage is OwnableStorage {
    MarketplaceConfig internal _config;

    mapping(address => bool) internal _eligibleForLootbox;
    mapping(address => uint256) internal _lootboxesBought;
    mapping(bytes32 => uint256) internal _salePrice;
}
