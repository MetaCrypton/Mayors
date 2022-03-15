// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./MarketplaceConfiguration.sol";
import "./MarketplacePrimary.sol";
import "./MarketplaceSecondary.sol";

contract Marketplace is MarketplaceConfiguration, MarketplacePrimary, MarketplaceSecondary {
    constructor(
        MarketplaceConfig memory config,
        uint256 lootboxesTotal,
        string memory seasonURI,
        address owner
    ) {
        _config = config;
        _seasonURI = seasonURI;
        _lootboxesLeft = lootboxesTotal;
        _owner = owner;

        emit LootboxesSaleStarted(lootboxesTotal, seasonURI);
    }
}
