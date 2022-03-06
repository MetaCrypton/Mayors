// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./NFTModifiers.sol";
import "./interfaces/INFT.sol";

contract NFTInventories is INFTInventories, NFTModifiers {
    function getInventory(uint256 tokenId) external view override isExistingToken(tokenId) returns (address) {
        return _inventories[tokenId];
    }
}
