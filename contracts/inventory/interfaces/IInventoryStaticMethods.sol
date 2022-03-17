// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/InventoryStructs.sol";

interface IInventoryStaticMethods {
    function getStoredAssets(
        uint256 startIndex,
        uint256 number,
        AssetType assetType
    ) external view returns (Asset[] memory);
}
