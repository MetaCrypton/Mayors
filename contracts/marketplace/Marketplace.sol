// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./MarketplaceConfiguration.sol";
import "./MarketplacePrimary.sol";
import "./MarketplaceSecondary.sol";

contract Marketplace is MarketplaceConfiguration, MarketplacePrimary, MarketplaceSecondary {
    constructor(
        MarketplaceConfig memory config,
        Season[] memory seasons,
        address owner
    ) {
        _config = config;
        _owner = owner;

        uint256 seasonsLength = seasons.length;
        if (seasonsLength == 0) revert MarketplaceErrors.NoSeasons();
        for (uint256 i = 0; i < seasonsLength; i++) {
            if (seasons[i].lootboxesNumber == 0) revert MarketplaceErrors.EmptySeason();
            _seasons.push(seasons[i]);
        }

        emit SeasonStarted(seasons[0].lootboxesNumber, seasons[0].uri);
    }
}
