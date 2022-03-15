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

    function finishLootboxesSale() external override isOwner {
        _lootboxesLeft = 0;
        emit LootboxesSaleFinished();
    }

    function startLootboxesSale(uint256 number, string calldata uri) external override isOwner {
        _seasonURI = uri;
        _lootboxesLeft = number;

        emit LootboxesSaleStarted(number, uri);
    }

    function addLootboxesForSale(uint256 number) external override isOwner {
        if (number == 0) revert MarketplaceErrors.NullValue();
        _lootboxesLeft += number;
        emit AddedLootboxesForSale(number);
    }

    function burnLootboxesForSale(uint256 number) external override isOwner {
        if (number == 0) revert MarketplaceErrors.NullValue();
        if (_lootboxesLeft <= number) {
            _lootboxesLeft = 0;
        } else {
            _lootboxesLeft -= number;
        }
        emit RemovedLootboxesForSale(number);
    }

    function updateSeason(string calldata uri) external override isOwner {
        if (keccak256(abi.encodePacked(_seasonURI)) == keccak256(abi.encodePacked(uri)))
            revert MarketplaceErrors.SameValue();
        _seasonURI = uri;

        emit SeasonUpdated(uri);
    }

    function getConfig() external view override returns (MarketplaceConfig memory) {
        return _config;
    }

    function getSeasonURI() external view override returns (string memory) {
        return _seasonURI;
    }
}
