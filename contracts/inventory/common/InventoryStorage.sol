// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./InventoryStructs.sol";
import "../../common/ownership/OwnableStorage.sol";
import "../../nft/NFT.sol";

contract InventoryStorage is OwnableStorage {
    NFT internal _nftContract;
    uint256 internal _nftId;

    AssetsSet internal _assetsSet;
}
