// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

interface IMarketplaceEvents {
    event ConfigUpdated();

    event AddedToWhiteList(address participant);

    event RemovedFromWhiteList(address participant);

    event LootboxBought(address buyer, address lootboxAddress, uint256 lootboxId);

    event ItemPriceSet(address addr, uint256 tokenId, uint256 price);

    event ItemPriceRemoved(address addr, uint256 tokenId);

    event ItemBought(address addr, uint256 tokenId, uint256 price);

    event SeasonStarted(uint256 number, string uri);
}
