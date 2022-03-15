// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/MarketplaceStructs.sol";

interface IMarketplacePrimary {
    function buyLootboxMP(uint256 index, bytes32[] calldata merkleProof) external returns (uint256);

    function buyLootbox() external returns (uint256);

    function addToWhiteList(address[] calldata participants) external;

    function removeFromWhiteList(address[] calldata participants) external;

    function isInWhiteList(address participant) external view returns (bool);

    function verifyMerkleProof(
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) external view returns (bool);
}
