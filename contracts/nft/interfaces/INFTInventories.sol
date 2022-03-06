// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

interface INFTInventories {
    function getInventory(uint256 tokenId) external view returns (address);
}
