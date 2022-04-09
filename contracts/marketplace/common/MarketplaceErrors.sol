// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

library MarketplaceErrors {
    error NotInMerkleTree();
    error NotInWhiteList();
    error TooManyLootboxesPerAddress();
    error NoSeasons();
    error EmptySeason();
    error SameValue();
    error NotTradable();
    error AlreadyOwner();
    error NotOnSale();
    error SameConfig();
    error NotValidPrice();
    error NotItemOwner();
    error UnexistingSeason();
    error ZeroPrice();
    error NoURI();
    error SeasonNotStarted();
    error SeasonFinished();
    error LootboxesEnded();
    error WrongTimestamps();
}
