// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IMarketplace.sol";
import "./MarketplaceErrors.sol";
import "./MarketplaceConfiguration.sol";

contract MarketplacePrimary is IMarketplacePrimary, IMarketplaceEvents, MarketplaceConfiguration {
    constructor(MarketplaceConfig memory config, address owner) MarketplaceConfiguration(config, owner) {}

    function buyLootbox() external override returns (uint256) {
        if (_config.lootboxesCap == 0) revert MarketplaceErrors.OutOfStock();
        if (!_eligibleForLootbox[msg.sender]) revert MarketplaceErrors.NotEligible();
        if (_lootboxesBought[msg.sender] >= _config.lootboxesPerAddress) revert MarketplaceErrors.TooManyLootboxes();

        _config.lootboxesCap--;
        _lootboxesBought[msg.sender]++;
        _eligibleForLootbox[msg.sender] = false;

        uint256 id = _config.lootbox.mint(msg.sender);
        emit LootboxBought(msg.sender, address(_config.lootbox), id);

        _config.paymentTokenPrimary.transferFrom(msg.sender, _config.feeAggregator, _config.lootboxPrice);

        return id;
    }

    function addToEligible(address[] calldata participants) external override isOwner {
        uint256 length = participants.length;
        for (uint256 i = 0; i < length; i++) {
            bool eligible = _eligibleForLootbox[participants[i]];
            if (!eligible) {
                _eligibleForLootbox[participants[i]] = true;
                emit AddedToEligible(participants[i]);
            }
        }
    }

    function removeFromEligible(address[] calldata participants) external override isOwner {
        uint256 length = participants.length;
        for (uint256 i = 0; i < length; i++) {
            bool eligible = _eligibleForLootbox[participants[i]];
            if (eligible) {
                _eligibleForLootbox[participants[i]] = false;
                emit RemovedFromEligible(participants[i]);
            }
        }
    }

    function isEligible(address participant) external view override returns (bool) {
        return _eligibleForLootbox[participant];
    }
}