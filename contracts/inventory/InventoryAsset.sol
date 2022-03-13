// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IInventoryAsset.sol";
import "./InventoryNFTOwner.sol";
import "./InventoryAssetsSet.sol";

contract InventoryAsset is IInventoryAsset, InventoryNFTOwner {
    using InventoryAssetsSet for *;

    function storeAsset(Asset memory asset) public override verifyNFTOwner {
        uint256 index = _assetsSet._getAssetIndexById(asset.id);
        if (index == 0) {
            emit AssetAdded(asset.id, asset.assetType, asset.data);
            _assetsSet._addAsset(asset);
        } else {
            Asset storage _asset = _assetsSet._getAssetByIndex(index);
            emit AssetUpdated(asset.id, asset.data);
            _asset._updateAsset(asset.data);
        }
    }

    function removeAsset(uint256 id) public override verifyNFTOwner {
        uint256 index = _assetsSet._getAssetIndexById(id);
        if (index == 0) revert InventoryErrors.UnexistingAsset();
        emit AssetRemoved(index);
        _assetsSet._removeAsset(index);
    }

    function getStoredAssets(
        uint256 startIndex,
        uint256 number,
        AssetType assetType
    ) public view override returns (Asset[] memory) {
        return _assetsSet._getAssetsByType(startIndex, number, assetType);
    }

    // function packEtherAsset(uint256 amount) external pure override returns (Asset memory) {
    //     uint256 id = uint256(keccak256(abi.encodePacked("Ether")));
    //     bytes memory data = abi.encode(EtherStruct(amount));
    //     return Asset(id, AssetType.Ether, data);
    // }

    // function unpackEtherAsset(Asset memory asset) external pure override returns (uint256 amount) {
    //     if (asset.assetType != AssetType.Ether) revert InventoryErrors.UnmatchingAssetType();

    //     EtherStruct memory data = abi.decode(asset.data, (EtherStruct));
    //     return data.amount;
    // }
}
