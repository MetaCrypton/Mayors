// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./IInventoryEvents.sol";

interface IInventory is IInventoryEvents {
    function storeAsset(Asset memory asset) external;

    function removeAsset(uint256 id) external;

    function getStoredAssets(
        uint256 startIndex,
        uint256 number,
        AssetType assetType
    ) external view returns (Asset[] memory);

    // function packEtherAsset(uint256 amount) external pure returns (Asset memory);

    // function packERC20Asset(address token, uint256 amount) external pure returns (Asset memory);

    // function packERC721Asset(address token, uint256 tokenId) external pure returns (Asset memory);

    // function unpackEtherAsset(Asset memory asset) external pure returns (uint256 amount);

    // function unpackERC20Asset(Asset memory asset) external pure returns (address token, uint256 amount);

    // function unpackERC721Asset(Asset memory asset) external pure returns (address token, uint256 tokenId);
}
