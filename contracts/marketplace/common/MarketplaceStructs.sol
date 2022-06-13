// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../../lootbox/Lootbox.sol";
import "../../nft/NFT.sol";
import "../../token/Token.sol";

struct Season {
    uint256 startTimestamp;
    uint256 endTimestamp;
    uint256 lootboxesNumber;
    uint256 lootboxPrice;
    uint256 lootboxesPerAddress;
    uint256 lootboxesUnlockTimestamp;
    uint256 nftNumberInLootbox;
    uint256 nftStartIndex;
    bytes32 merkleRoot;
    bool isPublic;
    string uri;
}

struct Item {
    address addr;
    uint256 tokenId;
}

struct ItemSale {
    address seller;
    uint256 price;
}

struct MarketplaceConfig {
    Lootbox lootbox;
    NFT nft;
    Token paymentTokenPrimary;
    Token paymentTokenSecondary;
    address feeAggregator;
}
