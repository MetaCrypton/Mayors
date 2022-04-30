// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/MarketplaceStructs.sol";

interface IMarketplacePrimary {
    function buyLootboxMP(
        uint256 seasonId,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external returns (uint256);

    function buyLootbox(uint256 seasonId) external returns (uint256);

    function sendLootboxes(
        uint256 seasonId,
        uint256 number,
        address recipient
    ) external;

    function addToWhiteList(uint256 seasonId, address[] calldata participants) external;

    function removeFromWhiteList(uint256 seasonId, address[] calldata participants) external;

    function isInWhiteList(uint256 seasonId, address participant) external view returns (bool);

    function verifyMerkleProof(
        uint256 seasonId,
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) external view returns (bool);

    function getSeason(uint256 seasonId) external view returns (Season memory);
}
