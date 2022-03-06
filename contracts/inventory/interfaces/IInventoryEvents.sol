// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/InventoryStructs.sol";

interface IInventoryEvents {
    event AssetAdded(uint256 indexed id, AssetType indexed assetType, bytes data);
    event AssetUpdated(uint256 indexed id, bytes data);
    event AssetRemoved(uint256 indexed id);
}
