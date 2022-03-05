// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./NFTConfiguration.sol";
import "./interfaces/INFT.sol";
import "./NFTConstants.sol";
import "../marketplace/MarketplaceStructs.sol";

contract NFTWithRarity is INFTWithRarity, NFTConfiguration {
    function getRarity(uint256 tokenId) external view override isExistingToken(tokenId) returns (Rarity) {
        return _rarities[tokenId];
    }

    //solhint-disable code-complexity
    //solhint-disable function-max-lines

    function calculateRarityAndHashrate(
        uint256 blockNumber,
        uint256 id,
        address owner
    ) public view override returns (Rarity, uint256) {
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

    //solhint-enable code-complexity
    //solhint-enable function-max-lines
}
