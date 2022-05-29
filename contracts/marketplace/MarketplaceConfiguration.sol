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
        _addNewSeasons(seasons);
    }

    function getConfig() external view override returns (MarketplaceConfig memory) {
        return _config;
    }

    function getSeasonsTotal() external view override returns (uint256) {
        return _seasons.length;
    }

    function getSeasons(uint256 start, uint256 number) external view override returns (Season[] memory) {
        if (start + number > _seasons.length) revert MarketplaceErrors.UnexistingSeason();

        Season[] memory seasons = new Season[](number);
        for (uint256 i = 0; i < number; i++) {
            seasons[i] = _seasons[start + i];
        }
        return seasons;
    }

    function _addNewSeasons(Season[] memory seasons) internal {
        uint256 seasonsLength = seasons.length;
        if (seasonsLength == 0) revert MarketplaceErrors.NoSeasons();
        for (uint256 i = 0; i < seasonsLength; i++) {
            Season memory season = seasons[i];
            _verifyNewSeason(season);
            _seasons.push(season);

            emit SeasonAdded(
                season.startTimestamp,
                season.endTimestamp,
                season.lootboxesNumber,
                season.lootboxPrice,
                season.lootboxesPerAddress,
                season.merkleRoot,
                season.uri
            );
        }
    }

    function _verifyNewSeason(Season memory season) internal pure {
        if (season.startTimestamp > season.endTimestamp) revert MarketplaceErrors.WrongTimestamps();
        if (season.lootboxesNumber == 0) revert MarketplaceErrors.EmptySeason();
        if (season.lootboxPrice == 0) revert MarketplaceErrors.ZeroPrice();
        if (season.lootboxesPerAddress == 0) revert MarketplaceErrors.ZeroLootboxesPerAddress();
        if (bytes(season.uri).length == 0) revert MarketplaceErrors.NoURI();
    }
}
