// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "./InventoryAsset.sol";
import "./common/InventoryErrors.sol";
import "./interfaces/IInventoryERC721.sol";

contract InventoryERC721 is IInventoryERC721, InventoryAsset {
    using InventoryAssetsSet for *;

    modifier verifyERC721Input(address token) {
        if (token == address(0x00)) revert InventoryErrors.EmptyAddress();
        _;
    }

    function depositERC721(
        address from,
        address token,
        uint256 tokenId
    ) external override verifyNFTOwner verifyERC721Input(token) {
        emit DepositERC721(from, token, tokenId);
        Asset memory asset = _packERC721Asset(token, tokenId);
        storeAsset(asset);
        IERC721(token).transferFrom(from, address(this), tokenId);
    }

    function withdrawERC721(
        address recipient,
        address token,
        uint256 tokenId
    ) external override verifyNFTOwner verifyERC721Input(token) {
        emit WithdrawERC721(recipient, token, tokenId);
        Asset memory asset = _packERC721Asset(token, tokenId);
        removeAsset(asset.id);
        IERC721(token).transferFrom(address(this), recipient, tokenId);
    }

    function isERC721Owner(address token, uint256 tokenId) external view override returns (bool) {
        Asset memory asset = _packERC721Asset(token, tokenId);
        uint256 index = _assetsSet._getAssetIndexById(asset.id);
        return index != 0;
    }

    function getERC721s(uint256 startIndex, uint256 number) external view override returns (ERC721Struct[] memory) {
        return _assetsSetListToERC721(getStoredAssets(startIndex, number, AssetType.ERC721));
    }

    function _packERC721Asset(address token, uint256 tokenId) internal pure returns (Asset memory) {
        uint256 id = uint256(keccak256(abi.encodePacked(token, tokenId)));
        bytes memory data = abi.encode(ERC721Struct(token, tokenId));
        return Asset(id, AssetType.ERC721, data);
    }

    function _unpackERC721Asset(Asset memory asset) internal pure returns (ERC721Struct memory) {
        if (asset.assetType != AssetType.ERC721) revert InventoryErrors.UnmatchingAssetType();
        return abi.decode(asset.data, (ERC721Struct));
    }

    function _assetsSetListToERC721(Asset[] memory assets) internal pure returns (ERC721Struct[] memory) {
        uint256 assetsLength = assets.length;
        ERC721Struct[] memory tokens = new ERC721Struct[](assetsLength);
        for (uint256 i = 0; i < assetsLength; i++) {
            tokens[i] = _unpackERC721Asset(assets[i]);
        }
        return tokens;
    }
}
