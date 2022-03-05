// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../MarketplaceStructs.sol";

interface IMarketplaceEvents {
    event ConfigUpdated();

    event AddedToEligible(address participant);

    event RemovedFromEligible(address participant);

    event LootboxBought(address buyer, address lootboxAddress, uint256 lootboxId);

    event SalePriceSet(address addr, uint256 tokenId, uint256 price);

    event ItemBought(address addr, uint256 tokenId, uint256 price);
}

interface IMarketplaceConfiguration {
    function updateConfig(MarketplaceConfig calldata config) external;

    function getConfig() external view returns (MarketplaceConfig memory);
}

interface IMarketplacePrimary {
    function buyLootboxMP(uint256 index, bytes32[] calldata merkleProof) external returns (uint256);

    function buyLootbox() external returns (uint256);

    function addToEligible(address[] calldata participants) external;

    function removeFromEligible(address[] calldata participants) external;

    function isEligible(address participant) external view returns (bool);

    function verifyMerkleProof(
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) external view returns (bool);
}

interface IMarketplaceSecondary {
    function setForSale(Item calldata item, uint256 price) external;

    function buyItem(Item calldata item) external;

    function initialize(MarketplaceConfig memory config, address owner) external;

    function getItemPrice(Item calldata item) external view returns (uint256);
}

interface IMarketplace is IMarketplaceEvents, IMarketplaceConfiguration, IMarketplacePrimary, IMarketplaceSecondary {}
