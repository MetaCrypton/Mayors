// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./IMarketplace.sol";
import "../lootbox/Lootbox.sol";
import "../common/ownership/Ownable.sol";

contract Marketplace is IMarketplace, Ownable {
    error NotEligible();
    error SameLootboxAddress();
    error SameLootboxPrice();

    Lootbox internal _lootbox;
    uint256 internal _lootboxPrice;
    mapping(address => bool) internal _eligibleForLootbox;

    constructor(
        address owner,
        address lootboxAddress,
        uint256 price
    ) Ownable(owner) {
        _lootbox = Lootbox(lootboxAddress);
        _lootboxPrice = price;
        emit LootboxAddressSet(lootboxAddress);
        emit LootboxPriceSet(price);
    }

    function buyLootbox() external override returns (uint256) {
        if (!_eligibleForLootbox[msg.sender]) revert NotEligible();

        _eligibleForLootbox[msg.sender] = false;

        uint256 id = _lootbox.mint(msg.sender);
        emit LootboxBought(msg.sender, address(_lootbox), id);

        return id;
    }

    function setLootboxAddress(address lootboxAddress) external override isOwner {
        if (address(_lootbox) == lootboxAddress) revert SameLootboxAddress();
        _lootbox = Lootbox(lootboxAddress);
        emit LootboxAddressSet(lootboxAddress);
    }

    function setLootboxPrice(uint256 price) external override isOwner {
        if (_lootboxPrice == price) revert SameLootboxPrice();
        _lootboxPrice = price;
        emit LootboxPriceSet(price);
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

    function getLootboxPrice() external view override returns (uint256) {
        return _lootboxPrice;
    }

    function setLootboxAddress() external view override returns (address) {
        return address(_lootbox);
    }
}
