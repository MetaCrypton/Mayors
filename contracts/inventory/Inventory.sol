// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IInventory.sol";
import "./InventoryNFTOwner.sol";
import "./InventoryAssetsSet.sol";

contract Inventory is IInventory, InventoryNFTOwner {
    using InventoryAssetsSet for *;

    constructor(uint256 id) {
        _nftContract = NFT(msg.sender);
        _nftId = id;
    }

    function storeAsset(Asset asset) internal override verifyNFTOwner {
        uint256 index = _assetsSet._getAssetIndexById(asset.id);
        if (index == 0) {
            emit AssetAdded(asset.id, asset.assetType, asset.data);
            _assetsSet._addAsset(asset);
        } else {
            emit AssetUpdated(asset.id, asset.data);
            _assetsSet._updateAsset(asset.data);
        }
    }

    function removeAsset(uint256 id) internal override verifyNFTOwner {
        uint256 index = _assetsSet._getAssetIndexById(id);
        if (index == 0) revert InventoryErrors.UnexistingAsset();
        emit AssetRemoved(index);
        _assetsSet._removeAsset(index);
    }

    function getStoredAssets(
        uint256 startIndex,
        uint256 number,
        AssetType assetType
    ) internal returns (Asset[] memory) {
        return _assetsSet._getAssetsByType(startIndex, number, assetType);
    }

    // function isAssetOwner(uint256 id) internal override returns (bool) {
    //     uint256 index = _assetsSet._getAssetIndexById(id);
    //     return index != 0;
    // }

    // function getBalance() {
    // }

    function packEtherAsset(uint256 amount) internal pure override returns (Asset) {
        uint256 id = uint256(keccak256(abi.encodePacked("Ether")));
        bytes memory data = abi.encode(EtherStruct(amount));
        return Asset(id, AssetType.Ether, data);
    }

    function packERC20Asset(address token, uint256 amount) internal pure override returns (Asset) {
        uint256 id = uint256(keccak256(abi.encodePacked(token)));
        bytes memory data = abi.encode(ERC20Struct(token, amount));
        return Asset(id, AssetType.ERC20, data);
    }

    function packERC721Asset(address token, uint256 tokenId) internal pure override returns (Asset) {
        uint256 id = uint256(keccak256(abi.encodePacked(token, tokenId)));
        bytes memory data = abi.encode(ERC721Struct(token, tokenId));
        return Asset(id, AssetType.ERC721, data);
    }

    function unpackEtherAsset(Asset asset) internal pure override returns (uint256 amount) {
        if (asset.assetType != AssetType.Ether) revert InventoryErrors.UnmatchingAssetType();

        EtherStruct memory data = abi.decode(asset.data, (EtherStruct));
        return data.amount;
    }

    function unpackERC20Asset(Asset asset) internal pure override returns (address token, uint256 amount) {
        if (asset.assetType != AssetType.ERC20) revert InventoryErrors.UnmatchingAssetType();

        ERC20Struct memory data = abi.decode(asset.data, (ERC20Struct));
        return (data.token, data.amount);
    }

    function unpackERC721Asset(Asset asset) internal pure override returns (address token, uint256 tokenId) {
        if (asset.assetType != AssetType.ERC721) revert InventoryErrors.UnmatchingAssetType();

        ERC721Struct memory data = abi.decode(asset.data, (ERC721Struct));
        return (data.token, data.tokenId);
    }
}