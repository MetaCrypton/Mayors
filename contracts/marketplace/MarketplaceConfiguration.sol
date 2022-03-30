// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IMarketplace.sol";
import "./common/MarketplaceErrors.sol";
import "./common/MarketplaceStorage.sol";
import "../common/ownership/Ownable.sol";

contract MarketplaceConfiguration is IMarketplaceConfiguration, IMarketplaceEvents, Ownable, MarketplaceStorage {
    function updateConfig(MarketplaceConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert MarketplaceErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function addNewSeasons(Season[] calldata seasons) external override isOwner {
        uint256 seasonsLength = seasons.length;
        if (seasonsLength == 0) revert MarketplaceErrors.NoSeasons();
        for (uint256 i = 0; i < seasonsLength; i++) {
            if (seasons[i].lootboxesNumber == 0) revert MarketplaceErrors.EmptySeason();
            _seasons.push(seasons[i]);
        }
    }

    function getConfig() external view override returns (MarketplaceConfig memory) {
        return _config;
    }

    function getSeasonURI() external view override returns (string memory) {
        return _seasons[_currentSeasonIndex].uri;
    }

    function getSeasonLootboxesLeft() external view override returns (uint256) {
        return _seasons[_currentSeasonIndex].lootboxesNumber;
    }
}
