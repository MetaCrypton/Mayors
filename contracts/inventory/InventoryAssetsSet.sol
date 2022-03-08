// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./common/InventoryStorage.sol";
import "./common/InventoryErrors.sol";
import "./common/InventoryStructs.sol";

library InventoryAssetsSet {
    function _addAsset(AssetsSet storage assets, Asset memory asset) internal {
        assets.assets.push(asset);
        assets.assetIndexById[asset.id] = assets.assets.length;
    }

    function _updateAsset(Asset storage asset, bytes memory data) internal {
        asset.data = data;
    }

    function _removeAsset(AssetsSet storage assets, uint256 index) internal {
        Asset storage old = _getAssetByIndex(assets, index);
        uint256 oldId = old.id;

        uint256 lastIndex = assets.assets.length - 1;
        Asset memory last = assets.assets[lastIndex];

        old.id = last.id;
        old.assetType = last.assetType;
        old.data = last.data;
        assets.assetIndexById[last.id] = index;

        assets.assets.pop();
        delete assets.assetIndexById[oldId];
    }

    function _getAssets(
        AssetsSet storage assets,
        uint256 startIndex,
        uint256 number
    ) internal view returns (Asset[] memory) {
        uint256 endIndex = startIndex + number;
        if (endIndex > assets.assets.length) revert InventoryErrors.WrongEndIndex();

        Asset[] memory assetsToReturn = new Asset[](number);
        for (uint256 i = startIndex; i < endIndex; i++) {
            assetsToReturn[i - startIndex] = assets.assets[i];
        }
        return assetsToReturn;
    }

    function _getAssetsByType(
        AssetsSet storage assets,
        uint256 startIndex,
        uint256 number,
        AssetType assetType
    ) internal view returns (Asset[] memory) {
        uint256 endIndex = startIndex + number;
        if (endIndex > assets.assets.length) revert InventoryErrors.WrongEndIndex();

        uint256 count = _countTokensByType(assets, startIndex, endIndex, assetType);
        Asset[] memory assetsToReturn = new Asset[](count);
        for (uint256 i = startIndex; i < endIndex; i++) {
            if (assets.assets[i].assetType == assetType) {
                assetsToReturn[i - startIndex] = assets.assets[i];
            }
        }
        return assetsToReturn;
    }

    function _countTokensByType(
        AssetsSet storage assets,
        uint256 startIndex,
        uint256 endIndex,
        AssetType assetType
    ) internal view returns (uint256) {
        uint256 counter = 0;
        for (uint256 i = startIndex; i < endIndex; i++) {
            if (assetType == assets.assets[i].assetType) {
                counter++;
            }
        }
        return counter;
    }

    function _getAssetByIndex(AssetsSet storage assets, uint256 index) internal view returns (Asset storage) {
        return assets.assets[index - 1];
    }

    function _getAssetIndexById(AssetsSet storage assets, uint256 id) internal view returns (uint256) {
        uint256 index = assets.assetIndexById[id];
        return index;
    }

    function _verifyAssetExists(AssetsSet storage assets, uint256 assetId) internal view {
        uint256 index = _getAssetIndexById(assets, assetId);
        if (index == 0) revert InventoryErrors.UnexistingAsset();
    }
}
