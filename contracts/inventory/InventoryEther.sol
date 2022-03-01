// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./InventoryConfiguration.sol";
import "./InventoryAssetsSet.sol";
import "./InventoryErrors.sol";
import "./interfaces/IInventory.sol";

contract InventoryEther is IInventoryEther, IInventoryEvents, InventoryConfiguration {
    using InventoryAssetsSet for *;

    modifier verifyEtherInput(uint256 amount) {
        if (amount == 0) revert InventoryErrors.ZeroAmount();
        _;
    }

    constructor(InventoryConfig memory config, address owner) InventoryConfiguration(config, owner) {}

    function depositEther() external payable override isOwner verifyEtherInput(msg.value) {
        // TODO:
        uint256 amount = msg.value;

        emit DepositEther(msg.sender, amount);

        uint256 id = _getEtherId();
        uint256 index = _assetsSet._getAssetIndexById(id);

        if (index == 0) {
            bytes memory data = abi.encode(EtherStruct(amount));
            emit AssetAdded(id, AssetType.Ether, data);
            _assetsSet._addAsset(id, AssetType.Ether, data);
        } else {
            Asset storage asset = _assetsSet._getAssetByIndex(index);
            EtherStruct memory storedEther = _assetToEther(asset);
            if (type(uint256).max - storedEther.amount < amount) revert InventoryErrors.DepositOverflow();
            storedEther.amount += amount;

            bytes memory data = abi.encode(storedEther);
            emit AssetUpdated(id, data);
            asset._updateAsset(data);
        }
    }

    function withdrawEther(address recipient, uint256 amount) external override isOwner verifyEtherInput(amount) {
        emit WithdrawEther(recipient, amount);

        uint256 id = _getEtherId();
        uint256 index = _assetsSet._getAssetIndexById(id);
        if (index == 0) revert InventoryErrors.UnexistingAsset();

        Asset storage asset = _assetsSet._getAssetByIndex(index);
        EtherStruct memory storedEther = _assetToEther(asset);
        if (storedEther.amount < amount) revert InventoryErrors.WithdrawOverflow();

        storedEther.amount -= amount;
        if (storedEther.amount > 0) {
            bytes memory data = abi.encode(storedEther);
            emit AssetUpdated(id, data);
            asset._updateAsset(data);
        } else {
            emit AssetRemoved(id);
            _assetsSet._removeAsset(index);
        }

        (bool success, ) = recipient.call{ value: amount }("");
        if (!success) revert InventoryErrors.EtherTransferFailed();
    }

    function getEtherBalance() external view override returns (uint256) {
        uint256 id = _getEtherId();
        uint256 index = _assetsSet._getAssetIndexById(id);
        if (index == 0) revert InventoryErrors.UnexistingAsset();

        Asset storage asset = _assetsSet._getAssetByIndex(index);
        EtherStruct memory storedEther = _assetToEther(asset);

        return storedEther.amount;
    }

    function _assetToEther(Asset memory asset) internal pure returns (EtherStruct memory) {
        if (asset.assetType != AssetType.Ether) revert InventoryErrors.UnmatchingAssetType();

        return abi.decode(asset.data, (EtherStruct));
    }

    function _getEtherId() internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked("Ether")));
    }
}
