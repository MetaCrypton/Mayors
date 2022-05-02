// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./LootboxERC721.sol";
import "./common/LootboxErrors.sol";
import "../marketplace/interfaces/IMarketplace.sol";

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

        uint256 seasonId = _seasonInfo[tokenId].id;
        Season memory season = IMarketplace(_config.marketplaceAddress).getSeason(seasonId);
        tokenIds = _config.nft.batchMint(
            msg.sender,
            seasonId,
            season.uri,
            season.nftStartIndex,
            season.nftNumberInLootbox
        );

        _burn(tokenId);
        delete _seasonInfo[tokenId];

        return tokenIds;
    }

    function mint(
        uint256 seasonId,
        string calldata seasonUri,
        address owner,
        uint256 unlockTimestamp
    ) external override isMarketplaceOrOwner returns (uint256 tokenId) {
        uint256 id = _tokenIdCounter++;
        _mint(owner, id);
        _seasonInfo[id] = SeasonInfo(seasonId, seasonUri);
        _unlockTimestamp[id] = unlockTimestamp;
        return id;
    }

    function batchMint(
        uint256 number,
        uint256 seasonId,
        string calldata seasonUri,
        address owner,
        uint256 unlockTimestamp
    ) external override isMarketplaceOrOwner {
        _balances[owner] += number;

        for (; number > 0; number--) {
            uint256 id = _tokenIdCounter++;
            _owners[id] = owner;
            _seasonInfo[id] = SeasonInfo(seasonId, seasonUri);
            _unlockTimestamp[id] = unlockTimestamp;

            emit Transfer(address(0), owner, id);
        }
    }

    function getUnlockTimestamp(uint256 tokenId) external view override returns (uint256) {
        return _unlockTimestamp[tokenId];
    }

    function getSeasonUriTimestamp(uint256 tokenId) external view override returns (string memory) {
        return _seasonInfo[tokenId].uri;
    }
}
