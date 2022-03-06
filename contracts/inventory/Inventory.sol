// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./common/InventoryStorage.sol";

contract Inventory is InventoryStorage {
    constructor(uint256 id) {
        _nftContract = NFT(msg.sender);
        _nftId = id;
    }
}
