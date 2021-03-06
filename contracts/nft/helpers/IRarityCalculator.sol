// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "../common/NFTStructs.sol";

interface IRarityCalculator {
    function calculateRarityAndHashrate(
        uint256 blockNumber,
        uint256 id,
        address owner
    ) external view returns (Rarity, uint256);

    function getHashrate(
        Level level,
        Rarity rarity,
        uint256 baseHashrate
    ) external pure returns (uint256);

    function getVoteMultiplier(Level level, Rarity rarity) external pure returns (uint256);

    function getVoteDiscount(Level level, Rarity rarity) external pure returns (uint256);
}
