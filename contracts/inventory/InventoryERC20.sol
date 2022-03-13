// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "./InventoryAsset.sol";
import "./common/InventoryErrors.sol";
import "./interfaces/IInventoryERC20.sol";

contract InventoryERC20 is IInventoryERC20, InventoryAsset {
    using InventoryAssetsSet for *;

    modifier verifyERC20Input(address token, uint256 amount) {
        if (token == address(0x00)) revert InventoryErrors.EmptyAddress();
        if (amount == 0) revert InventoryErrors.ZeroAmount();
        _;
    }

    function depositERC20(
        address from,
        address token,
        uint256 amount
    ) external override verifyNFTOwner verifyERC20Input(token, amount) {
        emit DepositERC20(from, token, amount);

        uint256 id = _getERC20Id(token);
        uint256 index = _assetsSet._getAssetIndexById(id);

        uint256 balance = 0;
        if (index != 0) {
            balance = _getERC20BalanceByIndex(token, index);
        }

        if (type(uint256).max - balance < amount) revert InventoryErrors.DepositOverflow();
        Asset memory asset = _packERC20Asset(token, balance + amount);
        storeAsset(asset);
        IERC20(token).transferFrom(from, address(this), amount);
    }

    function withdrawERC20(
        address recipient,
        address token,
        uint256 amount
    ) external override verifyNFTOwner verifyERC20Input(token, amount) {
        emit WithdrawERC20(recipient, token, amount);
        uint256 balance = getERC20Balance(token);
        if (balance < amount) revert InventoryErrors.WithdrawOverflow();
        balance -= amount;
        Asset memory asset = _packERC20Asset(token, balance);
        if (balance > 0) {
            storeAsset(asset);
        } else {
            removeAsset(asset.id);
        }
        IERC20(token).transfer(recipient, amount);
    }

    function getERC20s(uint256 startIndex, uint256 number) external view override returns (ERC20Struct[] memory) {
        return _assetsSetListToERC20(getStoredAssets(startIndex, number, AssetType.ERC20));
    }

    function getERC20Balance(address token) public view override returns (uint256) {
        uint256 id = _getERC20Id(token);
        uint256 index = _assetsSet._getAssetIndexById(id);
        if (index == 0) revert InventoryErrors.UnexistingAsset();
        return _getERC20BalanceByIndex(token, index);
    }

    function _getERC20BalanceByIndex(address token, uint256 index) internal view returns (uint256) {
        Asset storage asset = _assetsSet._getAssetByIndex(index);
        ERC20Struct memory storedToken = _unpackERC20Asset(asset);
        if (storedToken.tokenAddress != token) revert InventoryErrors.UnmatchingTokenAddress();

        return storedToken.amount;
    }

    function _getERC20Id(address token) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(token)));
    }

    function _packERC20Asset(address token, uint256 amount) internal pure returns (Asset memory) {
        uint256 id = _getERC20Id(token);
        bytes memory data = abi.encode(ERC20Struct(token, amount));
        return Asset(id, AssetType.ERC20, data);
    }

    function _unpackERC20Asset(Asset memory asset) internal pure returns (ERC20Struct memory) {
        if (asset.assetType != AssetType.ERC20) revert InventoryErrors.UnmatchingAssetType();
        return abi.decode(asset.data, (ERC20Struct));
    }

    function _assetsSetListToERC20(Asset[] memory assets) internal pure returns (ERC20Struct[] memory) {
        uint256 assetsLength = assets.length;
        ERC20Struct[] memory tokens = new ERC20Struct[](assetsLength);
        for (uint256 i = 0; i < assetsLength; i++) {
            tokens[i] = _unpackERC20Asset(assets[i]);
        }
        return tokens;
    }
}
