// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./common/InventoryStorage.sol";
import "./interfaces/IInventory.sol";
import "../common/proxy/initialization/IInitializable.sol";
import "../common/proxy/initialization/Initializable.sol";

contract InventoryInitializable is IInitializable, Initializable, InventoryStorage {
    error EmptyNftAddress();
    error EmptyUpgradesRegistry();

    function initialize(bytes memory input) public override(IInitializable, Initializable) {
        (uint256 nftId, address upgradesRegistry) = abi.decode(input, (uint256, address));
        // if (nftAddress == address(0x00)) revert EmptyNftAddress();
        if (upgradesRegistry == address(0x00)) revert EmptyUpgradesRegistry();
        // _nftAddress = nftAddress;
        _nftContract = NFT(msg.sender);
        _nftId = nftId;
        _upgradesRegistry = upgradesRegistry;

        _storeMethods(_methods[msg.sig]);

        super.initialize(input);
    }

    function _storeMethods(address upgradeAddress) internal {
        _methods[IInventory(address(0x00)).storeAsset.selector] = upgradeAddress;
        _methods[IInventory(address(0x00)).removeAsset.selector] = upgradeAddress;
        _methods[IInventory(address(0x00)).getStoredAssets.selector] = upgradeAddress;
    }
}
