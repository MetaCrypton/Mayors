// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

interface IMarketplaceEvents {
    event ConfigUpdated();

    event AddedToWhiteList(uint256 seasonId, address participant);

    event RemovedFromWhiteList(uint256 seasonId, address participant);

    event LootboxBought(uint256 seasonId, address buyer, address lootboxAddress, uint256 lootboxId);

    event ItemPriceSet(address addr, uint256 tokenId, uint256 price);

    event ItemPriceRemoved(address addr, uint256 tokenId);

    event ItemBought(address addr, uint256 tokenId, uint256 price);

    event SeasonAdded(
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 lootboxesNumber,
        uint256 lootboxPrice,
        uint256 lootboxesPerAddress,
        bytes32 merkleRoot,
        string uri
    );

    event LootboxesSentInBatch(uint256 seasonId, address recipient, address lootboxAddress, uint256 number);
}
