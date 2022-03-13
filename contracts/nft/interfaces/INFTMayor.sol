// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/NFTStructs.sol";

interface INFTMayor {
    function batchMint(address owner, string[] calldata names) external returns (uint256[] memory tokenIds);

    function updateLevel(uint256 tokenId) external;

    function getName(uint256 tokenId) external view returns (string memory);

    function getLevel(uint256 tokenId) external view returns (Level);

    function getHashrate(uint256 tokenId) external view returns (uint256);

    function getVotePrice(uint256 tokenId) external view returns (uint256);

    function getRarity(uint256 tokenId) external view returns (Rarity);

    function getHat(uint256 tokenId) external view returns (uint256);

    function getInHand(uint256 tokenId) external view returns (uint256);
}
