// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./LootboxERC721.sol";
import "./common/LootboxErrors.sol";

contract LootboxLifecycle is ILootboxLifecycle, ILootboxEvents, LootboxERC721 {
    modifier isMarketplaceOrOwner() {
        if (msg.sender != _config.marketplaceAddress && msg.sender != _owner) {
            revert LootboxErrors.NoPermission();
        }
        _;
    }

    function reveal(uint256 tokenId) external override returns (uint256[] memory tokenIds) {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert LootboxErrors.NoPermission();
        // solhint-disable-next-line not-rely-on-time
        if (_unlockTimestamp[tokenId] > block.timestamp) revert LootboxErrors.NotUnlocked();

        uint256 seasonId = _seasonIds[tokenId];
        SeasonInfo storage seasonInfo = _seasonInfo[seasonId];
        if (bytes(seasonInfo.uri).length == 0) revert LootboxErrors.NoSeasonInfo();

        tokenIds = _config.nft.batchMint(
            msg.sender,
            seasonId,
            seasonInfo.uri,
            seasonInfo.nftStartIndex,
            seasonInfo.nftNumberInLootbox
        );

        _burn(tokenId);
        delete _seasonIds[tokenId];
        if (seasonInfo.lootboxesCounter <= 1) {
            delete _seasonInfo[seasonId];
        } else {
            seasonInfo.lootboxesCounter--;
        }

        return tokenIds;
    }

    function mint(
        uint256 seasonId,
        string calldata seasonUri,
        uint256 nftStartIndex,
        uint256 nftNumberInLootbox,
        uint256 unlockTimestamp,
        address owner
    ) external override isMarketplaceOrOwner returns (uint256 tokenId) {
        uint256 id = _tokenIdCounter++;
        _mint(owner, id);
        _seasonIds[id] = seasonId;
        _unlockTimestamp[id] = unlockTimestamp;
        uint256 lootboxesCounter = 1;
        _addSeasonInfo(seasonId, lootboxesCounter, seasonUri, nftStartIndex, nftNumberInLootbox);
        return id;
    }

    function batchMint(
        uint256 number,
        uint256 seasonId,
        string calldata seasonUri,
        uint256 nftStartIndex,
        uint256 nftNumberInLootbox,
        uint256 unlockTimestamp,
        address owner
    ) external override isMarketplaceOrOwner {
        _balances[owner] += number;

        for (; number > 0; number--) {
            uint256 id = _tokenIdCounter++;
            _owners[id] = owner;
            _seasonIds[id] = seasonId;
            _unlockTimestamp[id] = unlockTimestamp;
            emit Transfer(address(0), owner, id);
        }
        _addSeasonInfo(seasonId, number, seasonUri, nftStartIndex, nftNumberInLootbox);
    }

    function getUnlockTimestamp(uint256 tokenId) external view override returns (uint256) {
        return _unlockTimestamp[tokenId];
    }

    function getSeasonUriTimestamp(uint256 tokenId) external view override returns (string memory) {
        return _seasonInfo[_seasonIds[tokenId]].uri;
    }

    function _addSeasonInfo(
        uint256 seasonId,
        uint256 lootboxesCounter,
        string calldata uri,
        uint256 nftStartIndex,
        uint256 nftNumberInLootbox
    ) internal {
        SeasonInfo memory seasonInfo = _seasonInfo[seasonId];
        if (bytes(seasonInfo.uri).length == 0) {
            _seasonInfo[seasonId] = SeasonInfo(lootboxesCounter, uri, nftStartIndex, nftNumberInLootbox);
            emit SeasonInfoAdded(seasonId, lootboxesCounter, uri, nftStartIndex, nftNumberInLootbox);
        }
    }
}
