// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./NFTERC721.sol";
import "./NFTModifiers.sol";
import "./interfaces/INFT.sol";
import "./helpers/IRarityCalculator.sol";
import "../marketplace/common/MarketplaceStructs.sol";
import "../inventory/Inventory.sol";

contract NFTMayor is INFTMayor, INFTEvents, NFTERC721, NFTModifiers {
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

            uint256 tokenId = _mintAndSetRarityAndHashrate(owner);
            tokenIds[i] = tokenId;
            _names[tokenId] = names[i];
            _inventories[tokenId] = _deployInventory(tokenId);
            emit NameSet(tokenId, names[i]);
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

    function getRarity(uint256 tokenId) external view override isExistingToken(tokenId) returns (Rarity) {
        return _rarities[tokenId];
    }

    function getHashrate(uint256 tokenId) external view override isExistingToken(tokenId) returns (uint256) {
        Level level = _levels[tokenId];
        Rarity rarity = _rarities[tokenId];
        uint256 baseHashrate = _baseHashrates[tokenId];

        return IRarityCalculator(_config.rarityCalculator).getHashrate(level, rarity, baseHashrate);
    }

    function getVotePrice(uint256 tokenId) external view override isExistingToken(tokenId) returns (uint256) {
        Level level = _levels[tokenId];
        Rarity rarity = _rarities[tokenId];

        return IRarityCalculator(_config.rarityCalculator).getVotePrice(level, rarity);
    }

    function _mintAndSetRarityAndHashrate(address owner) internal returns (uint256) {
        (uint256 id, Rarity rarity, uint256 hashrate) = _getRarityId(_tokenIdCounter++, owner);
        _mint(owner, id);
        _setRarityAndHashrate(id, rarity, hashrate);
        return id;
    }

    function _getRarityId(uint256 id, address owner)
        internal
        returns (
            uint256,
            Rarity,
            uint256
        )
    {
        (Rarity rarity, uint256 hashrate) = IRarityCalculator(_config.rarityCalculator).calculateRarityAndHashrate(
            block.number,
            id,
            owner
        );
        uint256 idRarity;
        if (rarity == Rarity.Common) {
            idRarity = _COMMONMIN + _commonIdCounter++;
        } else if (rarity == Rarity.Rare) {
            idRarity = _RAREMIN + _rareIdCounter++;
        } else if (rarity == Rarity.Epic) {
            idRarity = _EPICMIN + _epicIdCounter++;
        } else {
            idRarity = _LEGENDARYMIN + _legendaryIdCounter++;
        }
        return (idRarity, rarity, hashrate);
    }

    function _setRarityAndHashrate(
        uint256 id,
        Rarity rarity,
        uint256 hashrate
    ) internal {
        _rarities[id] = rarity;
        _baseHashrates[id] = hashrate;
    }

    function _deployInventory(uint256 tokenId) internal returns (address inventory) {
        return address(new Inventory(tokenId));
    }
}
