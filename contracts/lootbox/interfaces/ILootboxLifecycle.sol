// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

interface ILootboxLifecycle {
    function mint(
        uint256 seasonId,
        string calldata seasonUri,
        address owner,
        uint256 unlockTimestamp
    ) external returns (uint256 tokenId);

    function reveal(uint256 tokenId) external returns (uint256[] memory tokenIds);

    function batchMint(
        uint256 number,
        uint256 seasonId,
        string calldata seasonUri,
        address owner,
        uint256 unlockTimestamp
    ) external;

    function getUnlockTimestamp(uint256 tokenId) external view returns (uint256);

    function getSeasonUriTimestamp(uint256 tokenId) external view returns (string memory);
}
