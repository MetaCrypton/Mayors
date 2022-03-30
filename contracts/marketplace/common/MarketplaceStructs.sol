// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../../lootbox/Lootbox.sol";
import "../../nft/NFT.sol";
import "../../token/Token.sol";

struct Season {
    uint256 lootboxesNumber;
    string uri;
}

struct Item {
    address addr;
    uint256 tokenId;
}

struct MarketplaceConfig {
    Lootbox lootbox;
    NFT nft;
    Token paymentTokenPrimary;
    Token paymentTokenSecondary;
    address feeAggregator;
    uint256 lootboxPrice;
    uint256 lootboxesPerAddress;
    bytes32 merkleRoot;
}
