// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/MarketplaceStructs.sol";

interface IMarketplacePrimary {
    function buyLootboxMP(uint256 index, bytes32[] calldata merkleProof) external returns (uint256);

    function buyLootbox() external returns (uint256);

    function addToEligible(address[] calldata participants) external;

    function removeFromEligible(address[] calldata participants) external;

    function isEligible(address participant) external view returns (bool);

    function verifyMerkleProof(
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) external view returns (bool);
}
