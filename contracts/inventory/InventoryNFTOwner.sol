// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./common/InventoryStorage.sol";
import "./common/InventoryErrors.sol";

contract InventoryNFTOwner is InventoryStorage {
    modifier verifyNFTOwner() {
        if (msg.sender != _nftContract.ownerOf(_nftId)) revert InventoryErrors.NotNFTOwner();
        _;
    }
}
