// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IInventory.sol";
import "./InventoryConfiguration.sol";
import "./InventoryEther.sol";
import "./InventoryERC20.sol";
import "./InventoryERC721.sol";

contract Inventory is IInventoryEvents, InventoryERC721 {
    constructor(InventoryConfig memory config, address owner) InventoryERC721(config, owner) {}
}
