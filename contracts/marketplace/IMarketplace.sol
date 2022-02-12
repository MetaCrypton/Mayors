// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

interface IMarketplace {
    event LootboxAddressSet(address lootboxAddress);

    event LootboxPriceSet(uint256 lootboxPrice);

    event AddedToEligible(address participant);

    event RemovedFromEligible(address participant);

    event LootboxBought(address buyer, address lootboxAddress, uint256 lootboxId);

    function buyLootbox() external returns (uint256);

    function setLootboxAddress(address lootboxAddress) external;

    function setLootboxPrice(uint256 price) external;

    function addToEligible(address[] calldata participants) external;

    function removeFromEligible(address[] calldata participants) external;

    function isEligible(address participant) external view returns (bool);

    function getLootboxPrice() external view returns (uint256);

    function setLootboxAddress() external view returns (address);
}
