// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./NFTERC721.sol";
import "./NFTModifiers.sol";
import "./interfaces/INFT.sol";
import "./helpers/IRarityCalculator.sol";
import "./common/NFTConstants.sol";

contract NFTMayor is INFTMayor, INFTEvents, NFTERC721, NFTModifiers {
    function batchMint(
        address owner,
        uint256 seasonId,
        string calldata seasonUri,
        uint256 nftStartIndex,
        uint256 numberToMint
    ) external override isLootboxOrOwner returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](numberToMint);
        for (uint256 i = 0; i < numberToMint; i++) {
            uint256 tokenId = _mintAndSetRarityAndHashrate(owner, seasonId, nftStartIndex);
            tokenIds[i] = tokenId;
            _seasonURI[tokenId] = seasonUri;
        }

        return tokenIds;
    }

    function updateLevel(uint256 tokenId) external override isExistingToken(tokenId) isOwner {
        Level currentLevel = _levels[tokenId];
        if (uint8(currentLevel) == NFTConstants.MAX_LEVEL) revert NFTErrors.MaxLevel();
        _levels[tokenId] = Level(uint8(currentLevel) + 1);

        emit LevelUpdated(tokenId, Level(uint8(currentLevel) + 1));
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

    function getVotePrice(uint256 tokenId, uint256 votePrice)
        external
        view
        override
        isExistingToken(tokenId)
        returns (uint256)
    {
        return (votePrice * _getVoteMultiplier(tokenId)) / 100;
    }

    function getVoteDiscount(uint256 tokenId) public view override isExistingToken(tokenId) returns (uint256) {
        Level level = _levels[tokenId];
        Rarity rarity = _rarities[tokenId];

        return IRarityCalculator(_config.rarityCalculator).getVoteDiscount(level, rarity);
    }

    function _mintAndSetRarityAndHashrate(
        address owner,
        uint256 seasonId,
        uint256 nftStartIndex
    ) internal returns (uint256) {
        uint256 id = _calculateTokenId(seasonId, nftStartIndex);
        _mint(owner, id);
        _setRarityAndHashrate(id, owner);
        return id;
    }

    function _calculateTokenId(uint256 seasonId, uint256 nftStartIndex) internal returns (uint256) {
        uint256 seasonTokenIndex = _tokenCounterBySeason[seasonId]++;
        return nftStartIndex + seasonTokenIndex;
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

    function _getVoteMultiplier(uint256 tokenId) internal view isExistingToken(tokenId) returns (uint256) {
        Level level = _levels[tokenId];
        Rarity rarity = _rarities[tokenId];

        return IRarityCalculator(_config.rarityCalculator).getVoteMultiplier(level, rarity);
    }
}
