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

        tokenIds = _config.nft.batchMint(msg.sender, _seasonURI[tokenId], _config.numberInLootbox);

        _burn(tokenId);
        delete _seasonURI[tokenId];

        return tokenIds;
    }

    function mint(
        string calldata seasonURI,
        address owner,
        uint256 unlockTimestamp
    ) external override isMarketplaceOrOwner returns (uint256 tokenId) {
        uint256 id = _tokenIdCounter++;
        _mint(owner, id);
        _seasonURI[id] = seasonURI;
        _unlockTimestamp[id] = unlockTimestamp;
        return id;
    }

    function batchMint(
        uint256 number,
        string calldata seasonURI,
        address owner,
        uint256 unlockTimestamp
    ) external override isMarketplaceOrOwner {
        _balances[owner] += number;

        while (number-- > 1) {
            uint256 id = _tokenIdCounter++;
            _owners[id] = owner;
            _seasonURI[id] = seasonURI;
            _unlockTimestamp[id] = unlockTimestamp;

            emit Transfer(address(0), owner, id);
        }
    }
}
