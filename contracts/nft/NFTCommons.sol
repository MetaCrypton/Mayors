// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./NFTStorage.sol";
import "./NFTErrors.sol";

contract NFTCommons is NFTStorage {
    // TODO: :)
    error HUI(address hui);
    modifier isLootboxOrOwner() {
        if (msg.sender != _config.lootboxAddress && msg.sender != _owner) {
            revert NFTErrors.NoPermission();
        }
        _;
    }

    modifier isExistingToken(uint256 tokenId) {
        if (_tokenIdCounter <= tokenId) revert NFTErrors.UnexistingToken();
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) NFTStorage(name_, symbol_, owner) {}
}
