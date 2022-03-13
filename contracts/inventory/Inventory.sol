// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IInventory.sol";
import "./InventoryERC20.sol";
import "./InventoryERC721.sol";

contract Inventory is IInventory, InventoryERC721, InventoryERC20 {
    constructor(uint256 id) {
        _nftContract = NFT(msg.sender);
        _nftId = id;
    }
}
