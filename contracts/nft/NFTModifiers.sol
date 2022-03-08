// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./common/NFTStorage.sol";
import "./common/NFTErrors.sol";

contract NFTModifiers is NFTStorage {
    modifier isLootboxOrOwner() {
        if (msg.sender != _config.lootboxAddress && msg.sender != _owner) {
            revert NFTErrors.NoPermission();
        }
        _;
    }

    modifier isExistingToken(uint256 tokenId) {
        if ((tokenId < _RAREMIN) && (_COMMONMIN + _commonIdCounter <= tokenId)) {
            revert NFTErrors.UnexistingToken();
        } else if ((tokenId < _EPICMIN) && (_RAREMIN + _rareIdCounter <= tokenId)) {
            revert NFTErrors.UnexistingToken();
        } else if ((tokenId < _LEGENDARYMIN) && (_EPICMIN + _epicIdCounter <= tokenId)) {
            revert NFTErrors.UnexistingToken();
        } else if (_LEGENDARYMIN + _legendaryIdCounter <= tokenId) revert NFTErrors.UnexistingToken();
        _;
    }
}
