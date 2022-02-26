// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./MarketplaceStructs.sol";

interface IMarketplace {
    event ConfigUpdated();

    event AddedToEligible(address participant);

    event RemovedFromEligible(address participant);

    event LootboxBought(address buyer, address lootboxAddress, uint256 lootboxId);

    event SalePriceSet(address addr, uint256 tokenId, uint256 price);

    event ItemBought(address addr, uint256 tokenId, uint256 price);

    function setForSale(Item calldata item, uint256 price) external;

    function buyItem(Item calldata item) external;

    function buyLootbox() external returns (uint256);

    function updateConfig(MarketplaceConfig calldata config) external;

    function addToEligible(address[] calldata participants) external;

    function removeFromEligible(address[] calldata participants) external;

    function isEligible(address participant) external view returns (bool);

    function getItemPrice(Item calldata item) external view returns (uint256);

    function getConfig() external view returns (MarketplaceConfig memory);
}
