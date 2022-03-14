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

    function setLootboxesForSale(uint256 number) external override isOwner {
        if (number == _lootboxesForSale) revert MarketplaceErrors.SameValue();
        _lootboxesForSale = number;
        emit SetLootboxesForSale(number);
    }

    function addLootboxesForSale(uint256 number) external override isOwner {
        if (number == 0) revert MarketplaceErrors.NullValue();
        _lootboxesForSale += number;
        emit AddedLootboxesForSale(number);
    }

    function burnLootboxesForSale(uint256 number) external override isOwner {
        if (number == 0) revert MarketplaceErrors.NullValue();
        if (_lootboxesForSale <= number) {
            _lootboxesForSale = 0;
        } else {
            _lootboxesForSale -= number;
        }
        emit RemovedLootboxesForSale(number);
    }

    function getConfig() external view override returns (MarketplaceConfig memory) {
        return _config;
    }
}
