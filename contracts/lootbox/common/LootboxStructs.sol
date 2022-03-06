// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../../nft/NFT.sol";

struct LootboxConfig {
    uint8 numberInLootbox;
    address marketplaceAddress;
    NFT nft;
}
