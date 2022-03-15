// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

interface ILootboxLifecycle {
    function mint(string calldata seasonURI, address owner) external returns (uint256 tokenId);

    function reveal(uint256 tokenId, string[] memory names) external returns (uint256[] memory tokenIds);

    function batchMint(
        uint256 number,
        string calldata seasonURI,
        address owner
    ) external;
}
