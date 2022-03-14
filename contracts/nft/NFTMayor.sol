// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./NFTERC721.sol";
import "./NFTModifiers.sol";
import "./interfaces/INFT.sol";
import "./helpers/IRarityCalculator.sol";
import "./common/NFTConstants.sol";
import "../marketplace/common/MarketplaceStructs.sol";

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
            emit NameSet(tokenId, names[i]);
        }

        return tokenIds;
    }

    function updateLevel(uint256 tokenId) external override isExistingToken(tokenId) isOwner {
        if (_config.levelUpgradesAddress != msg.sender) revert NFTErrors.NotEligible();
        Level currentLevel = _levels[tokenId];
        if (uint8(currentLevel) == NFTConstants.MAX_LEVEL) revert NFTErrors.MaxLevel();
        _levels[tokenId] = Level(uint8(currentLevel) + 1);

        if (currentLevel == Level.Gen0) {
            _hatId[tokenId] = _hatIdCounter++;
        } else if (currentLevel == Level.Gen1) {
            _inHandId[tokenId] = _inHandIdCounter++;
        }

        emit LevelUpdated(tokenId, Level(uint8(currentLevel) + 1));
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

    function getHat(uint256 tokenId) external view override isExistingToken(tokenId) returns (uint256) {
        uint256 result = _hatId[tokenId];
        if (result == 0) revert NFTErrors.NoHat();
        return result;
    }

    function getInHand(uint256 tokenId) external view override isExistingToken(tokenId) returns (uint256) {
        uint256 result = _inHandId[tokenId];
        if (result == 0) revert NFTErrors.NoInHand();
        return result;
    }

    function getTokenSeasonId(uint256 tokenId) external view override isExistingToken(tokenId) returns (uint256) {
        return _getTokenSeasonId(tokenId);
    }

    function _mintAndSetRarityAndHashrate(address owner) internal returns (uint256) {
        uint256 id = _tokenIdCounter++;
        _mint(owner, id);
        _setRarityAndHashrate(id, owner);
        return id;
    }

    function _setRarityAndHashrate(uint256 id, address owner) internal {
        (Rarity rarity, uint256 hashrate) = IRarityCalculator(_config.rarityCalculator).calculateRarityAndHashrate(
            block.number,
            id,
            owner
        );
        _rarities[id] = rarity;
        _baseHashrates[id] = hashrate;
    }
}
