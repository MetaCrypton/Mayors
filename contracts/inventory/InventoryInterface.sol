// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IInventory.sol";
import "./interfaces/IInventoryStaticMethods.sol";
import "./InventoryNFTOwner.sol";
import "./InventoryAssetsSet.sol";
import "./InventoryInitializable.sol";
import "./InventoryUpgradable.sol";
import "../common/proxy/contract-interface/Interface.sol";
import "../common/upgradability/IUpgradable.sol";
import "../common/upgradability/IUpgrade.sol";
import "../common/upgradability/IUpgradableStaticMethods.sol";
import "../common/upgradability/IUpgradeStaticMethods.sol";

contract InventoryInterface is IInventory, IUpgradable, IUpgrade, Interface {
    function storeAsset(Asset memory asset) external override {
        asset;
        _delegateCall();
    }

    function removeAsset(uint256 id) external override {
        id;
        _delegateCall();
    }

    function upgrade(uint256 upgradeIndex) external override {
        upgradeIndex;
        _delegateCall();
    }

    function applyUpgrade() external override {
        _delegateCall();
    }

    function getStoredAssets(
        uint256 startIndex,
        uint256 number,
        AssetType assetType
    ) external view override returns (Asset[] memory) {
        bytes memory data = abi.encodeWithSelector(
            IInventoryStaticMethods(address(0x00)).getStoredAssets.selector,
            startIndex,
            number,
            assetType
        );
        _staticCall(data);
    }

    function getProxyId() external view override returns (bytes32 result) {
        result;
        bytes memory data = abi.encodeWithSelector(IUpgradeStaticMethods(address(0x00)).getProxyId_.selector);
        _staticCall(data);
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool result) {
        result;
        bytes memory data = abi.encodeWithSelector(
            IUpgradeStaticMethods(address(0x00)).supportsInterface_.selector,
            interfaceId
        );
        _staticCall(data);
    }

    // function getCurrentUpgrades_() external view override returns (uint256[] memory) {
    //     bytes memory data = abi.encodeWithSelector(
    //         IUpgradableStaticMethods(address(0x00)).getCurrentUpgrades_.selector
    //     );
    //     _staticCall(data);
    // }

    // function getMaxPossibleUpgradeIndex_() external view override returns (uint256) {
    //     bytes memory data = abi.encodeWithSelector(
    //         IUpgradableStaticMethods(address(0x00)).getMaxPossibleUpgradeIndex_.selector
    //     );
    //     _staticCall(data);
    // }

    function getCurrentUpgrades() public view override returns (uint256[] memory) {
        bytes memory data = abi.encodeWithSelector(IUpgradable(address(0x00)).getCurrentUpgrades.selector);
        _staticCall(data);
    }

    function getMaxPossibleUpgradeIndex() public view override returns (uint256) {
        bytes memory data = abi.encodeWithSelector(IUpgradable(address(0x00)).getMaxPossibleUpgradeIndex.selector);
        _staticCall(data);
    }
}
