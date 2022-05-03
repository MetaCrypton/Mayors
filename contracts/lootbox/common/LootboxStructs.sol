// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../../nft/NFT.sol";

struct LootboxConfig {
    address marketplaceAddress;
    NFT nft;
}

struct SeasonInfo {
    uint256 lootboxesCounter;
    string uri;
    uint256 nftStartIndex;
    uint256 nftNumberInLootbox;
}
