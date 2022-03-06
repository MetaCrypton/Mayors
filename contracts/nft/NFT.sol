// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./NFTConfiguration.sol";
import "./NFTWithRarity.sol";
import "./interfaces/INFT.sol";
import "./NFTConstants.sol";
import "../marketplace/MarketplaceStructs.sol";

contract NFT is INFTMayor, INFTEvents, NFTConfiguration {
    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) NFTConfiguration(name_, symbol_, owner) {}

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

    function getRarity(uint256 tokenId) external view override isExistingToken(tokenId) returns (Rarity) {
        return _rarities[tokenId];
    }

    function getHashrate(uint256 tokenId) external view override isExistingToken(tokenId) returns (uint256) {
        Level level = _levels[tokenId];
        Rarity rarity = _rarities[tokenId];
        uint256 baseHashrate = _baseHashrates[tokenId];

        return NFTWithRarity.getHashrate(level, rarity, baseHashrate);
    }

    function getVotePrice(uint256 tokenId) external view override isExistingToken(tokenId) returns (uint256) {
        Level level = _levels[tokenId];
        Rarity rarity = _rarities[tokenId];

        return NFTWithRarity.getVotePrice(level, rarity);
    }

    function _mintAndSetRarityAndHashrate(address owner) internal returns (uint256) {
        uint256 id = _tokenIdCounter++;
        _mint(owner, id);
        _setRarityAndHashrate(id, owner);
        return id;
    }

    function _setRarityAndHashrate(uint256 id, address owner) internal {
        (Rarity rarity, uint256 hashrate) = NFTWithRarity.calculateRarityAndHashrate(block.number, id, owner);
        _rarities[id] = rarity;
        _baseHashrates[id] = hashrate;
    }
}
