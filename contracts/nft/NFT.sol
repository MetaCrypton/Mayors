// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./NFTWithRarity.sol";
import "./interfaces/INFT.sol";
import "./NFTConstants.sol";
import "../marketplace/MarketplaceStructs.sol";
import "../inventory/Inventory.sol";

contract NFT is INFTMayor, INFTEvents, NFTWithRarity {
    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) NFTWithRarity(name_, symbol_, owner) {}

    function batchMint(address owner, string[] calldata names)
        external
        override
        isLootboxOrOwner
        returns (uint256[] memory tokenIds)
    {
        if (names.length > type(uint8).max) revert NFTErrors.Overflow();
        uint256 length = names.length;

        tokenIds = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            if (bytes(names[i]).length == 0) revert NFTErrors.EmptyName();

            tokenIds[i] = _mintAndSetRarityAndHashrate(owner);
            // _inventories[tokenIds[i]] = _deployInventory(owner);
            _names[tokenIds[i]] = names[i];
            emit NameSet(tokenIds[i], names[i]);
        }

        return tokenIds;
    }

    function updateLevel(uint256 tokenId, Level level) external override isExistingToken(tokenId) {
        if (_config.levelUpgradesAddress != msg.sender) revert NFTErrors.NotEligible();
        if (_levels[tokenId] == level) revert NFTErrors.SameValue();
        _levels[tokenId] = level;
        emit LevelUpdated(tokenId, level);
    }

    function getName(uint256 tokenId) external view override isExistingToken(tokenId) returns (string memory) {
        return _names[tokenId];
    }

    function getLevel(uint256 tokenId) external view override isExistingToken(tokenId) returns (Level) {
        return _levels[tokenId];
    }

    //solhint-disable code-complexity
    //solhint-disable function-max-lines

    function getHashrate(uint256 tokenId) external view override returns (uint256) {
        Level level = _levels[tokenId];
        Rarity rarity = _rarities[tokenId];
        uint256 baseHashrate = _baseHashrates[tokenId];

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

    function getVotePrice(uint256 tokenId) external view override isExistingToken(tokenId) returns (uint256) {
        Level level = _levels[tokenId];
        Rarity rarity = _rarities[tokenId];

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

    function _mintAndSetRarityAndHashrate(address owner) internal returns (uint256) {
        uint256 id = _tokenIdCounter++;
        _mint(owner, id);
        _setRarityAndHashrate(id, owner);
        return id;
    }

    function _setRarityAndHashrate(uint256 id, address owner) internal {
        (Rarity rarity, uint256 hashrate) = calculateRarityAndHashrate(block.number, id, owner);
        _rarities[id] = rarity;
        _baseHashrates[id] = hashrate;
    }

    // function _deployInventory(address owner) internal returns (address inventory) {
    //     return address(new Inventory(address(this), owner));
    // }
}
