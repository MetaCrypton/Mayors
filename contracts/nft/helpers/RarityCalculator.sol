// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./IRarityCalculator.sol";
import "../common/NFTConstants.sol";
import "../common/NFTErrors.sol";

contract RarityCalculator is IRarityCalculator {
    //solhint-disable code-complexity
    //solhint-disable function-max-lines

    function calculateRarityAndHashrate(
        uint256 blockNumber,
        uint256 id,
        address owner
    ) external view override returns (Rarity, uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(blockhash(blockNumber), id, owner)));
        uint256 rarityRate = random % NFTConstants.LEGENDARY_RATE;
        uint256 randomForRange = (random - (random % 10));
        if (rarityRate < NFTConstants.COMMON_RATE) {
            uint256 range = NFTConstants.COMMON_RANGE_MAX - NFTConstants.COMMON_RANGE_MIN + 1;
            return (Rarity.Common, (randomForRange % range) + NFTConstants.COMMON_RANGE_MIN);
        } else if (rarityRate < NFTConstants.RARE_RATE) {
            uint256 range = NFTConstants.RARE_RANGE_MAX - NFTConstants.RARE_RANGE_MIN + 1;
            return (Rarity.Rare, (randomForRange % range) + NFTConstants.RARE_RANGE_MIN);
        } else if (rarityRate < NFTConstants.EPIC_RATE) {
            uint256 range = NFTConstants.EPIC_RANGE_MAX - NFTConstants.EPIC_RANGE_MIN + 1;
            return (Rarity.Epic, (randomForRange % range) + NFTConstants.EPIC_RANGE_MIN);
        } else if (rarityRate < NFTConstants.LEGENDARY_RATE) {
            uint256 range = NFTConstants.LEGENDARY_RANGE_MAX - NFTConstants.LEGENDARY_RANGE_MIN + 1;
            return (Rarity.Legendary, (randomForRange % range) + NFTConstants.LEGENDARY_RANGE_MIN);
        } else {
            revert NFTErrors.Overflow();
        }
    }

    function getHashrate(
        Level level,
        Rarity rarity,
        uint256 baseHashrate
    ) external pure override returns (uint256) {
        if (rarity == Rarity.Common) {
            if (level == Level.Gen0) {
                return baseHashrate * NFTConstants.HASHRATE_MULTIPLIERS_COMMON_GEN0;
            } else if (level == Level.Gen1) {
                return baseHashrate * NFTConstants.HASHRATE_MULTIPLIERS_COMMON_GEN1;
            } else if (level == Level.Gen2) {
                return baseHashrate * NFTConstants.HASHRATE_MULTIPLIERS_COMMON_GEN2;
            } else {
                revert NFTErrors.WrongLevel();
            }
        } else if (rarity == Rarity.Rare) {
            if (level == Level.Gen0) {
                return baseHashrate * NFTConstants.HASHRATE_MULTIPLIERS_RARE_GEN0;
            } else if (level == Level.Gen1) {
                return baseHashrate * NFTConstants.HASHRATE_MULTIPLIERS_RARE_GEN1;
            } else if (level == Level.Gen2) {
                return baseHashrate * NFTConstants.HASHRATE_MULTIPLIERS_RARE_GEN2;
            } else {
                revert NFTErrors.WrongLevel();
            }
        } else if (rarity == Rarity.Epic) {
            if (level == Level.Gen0) {
                return baseHashrate * NFTConstants.HASHRATE_MULTIPLIERS_EPIC_GEN0;
            } else if (level == Level.Gen1) {
                return baseHashrate * NFTConstants.HASHRATE_MULTIPLIERS_EPIC_GEN1;
            } else if (level == Level.Gen2) {
                return baseHashrate * NFTConstants.HASHRATE_MULTIPLIERS_EPIC_GEN2;
            } else {
                revert NFTErrors.WrongLevel();
            }
        } else if (rarity == Rarity.Legendary) {
            if (level == Level.Gen0) {
                return baseHashrate * NFTConstants.HASHRATE_MULTIPLIERS_LEGENDARY_GEN0;
            } else if (level == Level.Gen1) {
                return baseHashrate * NFTConstants.HASHRATE_MULTIPLIERS_LEGENDARY_GEN1;
            } else if (level == Level.Gen2) {
                return baseHashrate * NFTConstants.HASHRATE_MULTIPLIERS_LEGENDARY_GEN2;
            } else {
                revert NFTErrors.WrongLevel();
            }
        } else {
            revert NFTErrors.WrongRarity();
        }
    }

    function getVotePrice(Level level, Rarity rarity) external pure override returns (uint256) {
        if (rarity == Rarity.Common) {
            if (level == Level.Gen0) {
                return (NFTConstants.VOTE_PRICE * NFTConstants.VOTE_MULTIPLIER_COMMON_GEN0) / 100;
            } else if (level == Level.Gen1) {
                return (NFTConstants.VOTE_PRICE * NFTConstants.VOTE_MULTIPLIER_COMMON_GEN1) / 100;
            } else if (level == Level.Gen2) {
                return (NFTConstants.VOTE_PRICE * NFTConstants.VOTE_MULTIPLIER_COMMON_GEN2) / 100;
            } else {
                revert NFTErrors.WrongLevel();
            }
        } else if (rarity == Rarity.Rare) {
            if (level == Level.Gen0) {
                return (NFTConstants.VOTE_PRICE * NFTConstants.VOTE_MULTIPLIER_RARE_GEN0) / 100;
            } else if (level == Level.Gen1) {
                return (NFTConstants.VOTE_PRICE * NFTConstants.VOTE_MULTIPLIER_RARE_GEN1) / 100;
            } else if (level == Level.Gen2) {
                return (NFTConstants.VOTE_PRICE * NFTConstants.VOTE_MULTIPLIER_RARE_GEN2) / 100;
            } else {
                revert NFTErrors.WrongLevel();
            }
        } else if (rarity == Rarity.Epic) {
            if (level == Level.Gen0) {
                return (NFTConstants.VOTE_PRICE * NFTConstants.VOTE_MULTIPLIER_EPIC_GEN0) / 100;
            } else if (level == Level.Gen1) {
                return (NFTConstants.VOTE_PRICE * NFTConstants.VOTE_MULTIPLIER_EPIC_GEN1) / 100;
            } else if (level == Level.Gen2) {
                return (NFTConstants.VOTE_PRICE * NFTConstants.VOTE_MULTIPLIER_EPIC_GEN2) / 100;
            } else {
                revert NFTErrors.WrongLevel();
            }
        } else if (rarity == Rarity.Legendary) {
            if (level == Level.Gen0) {
                return (NFTConstants.VOTE_PRICE * NFTConstants.VOTE_MULTIPLIER_LEGENDARY_GEN0) / 100;
            } else if (level == Level.Gen1) {
                return (NFTConstants.VOTE_PRICE * NFTConstants.VOTE_MULTIPLIER_LEGENDARY_GEN1) / 100;
            } else if (level == Level.Gen2) {
                return (NFTConstants.VOTE_PRICE * NFTConstants.VOTE_MULTIPLIER_LEGENDARY_GEN2) / 100;
            } else {
                revert NFTErrors.WrongLevel();
            }
        } else {
            revert NFTErrors.WrongRarity();
        }
    }

    //solhint-enable code-complexity
    //solhint-enable function-max-lines
}
