// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/ILootbox.sol";
import "./LootboxConfiguration.sol";
import "./LootboxErrors.sol";
import "../proxy/UUPSUpgradeable.sol";

contract Lootbox is ILootboxLifecycle, ILootboxEvents, LootboxConfiguration, UUPSUpgradeable {
    modifier isMarketplaceOrOwner() {
        if (msg.sender != _config.marketplaceAddress && msg.sender != _owner) {
            revert LootboxErrors.NoPermission();
        }
        _;
    }

    function reveal(uint256 tokenId, string[] calldata names) external override returns (uint256[] memory tokenIds) {
        if (names.length != _config.numberInLootbox) revert LootboxErrors.Overflow();
        require(_isApprovedOrOwner(msg.sender, tokenId), "reveal: reveal caller is not owner nor approved");

        tokenIds = _config.nft.batchMint(msg.sender, names);
        _burn(tokenId);

        return tokenIds;
    }

    /**
     * @dev Mints `tokenId`. See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function mint(address owner) public override isMarketplaceOrOwner returns (uint256 tokenId) {
        uint256 id = _tokenIdCounter++;
        _mint(owner, id);
        return id;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner
    ) public override initializer {
        __lootboxStorageInit(name_, symbol_, owner);
        __uupsUpgradeableInit();
    }

    function _authorizeUpgrade(address newImplementation) internal override isOwner {}
}
