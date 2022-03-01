// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./InventoryStructs.sol";
import "../common/ownership/Ownable.sol";

contract InventoryStorage is Ownable {
    InventoryConfig internal _config;

    AssetsSet internal _assetsSet;

    constructor(InventoryConfig memory config, address owner) Ownable(owner) {
        _config = config;
    }
}
