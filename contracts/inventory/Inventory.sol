// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IInventory.sol";
import "./InventoryConfiguration.sol";
import "./InventoryEther.sol";

contract Inventory is IInventoryEvents, InventoryEther {
    constructor(InventoryConfig memory config, address owner) InventoryEther(config, owner) {}
}
