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

    function reveal(uint256 tokenId, string[] calldata names) external override returns (uint256[] memory tokenIds) {
        if (names.length != _config.numberInLootbox) revert LootboxErrors.Overflow();
        require(_isApprovedOrOwner(msg.sender, tokenId), "reveal: reveal caller is not owner nor approved");

        tokenIds = _config.nft.batchMint(msg.sender, _seasonURI[tokenId], names);

        _burn(tokenId);
        delete _seasonURI[tokenId];

        return tokenIds;
    }

    /**
     * @dev Mints `tokenId`. See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function mint(string memory seasonURI, address owner)
        public
        override
        isMarketplaceOrOwner
        returns (uint256 tokenId)
    {
        uint256 id = _tokenIdCounter++;
        _mint(owner, id);
        _seasonURI[id] = seasonURI;
        return id;
    }
}
