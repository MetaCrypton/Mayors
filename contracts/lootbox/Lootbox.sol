// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./ILootbox.sol";
import "../nft/Mayor.sol";
import "../common/interfaces/IERC721.sol";
import "../common/ownership/Ownable.sol";

contract Lootbox is ILootbox, ERC721, Ownable {
    address internal _marketplaceAddress;
    Mayor internal _nft;
    uint8 internal _numberInLootbox;

    error SameAddress();
    error SameValue();
    error NoPermission();
    error Overflow();

    modifier isMarketplaceOrOwner() {
        if (msg.sender != _marketplaceAddress && msg.sender != _owner) {
            revert NoPermission();
        }
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address owner,
        address token,
        uint8 numberInLootbox
    ) Ownable(owner) ERC721(name_, symbol_) {
        _nft = Mayor(token);
        _numberInLootbox = numberInLootbox;
        emit NFTAddressSet(token);
        emit NumberInLootboxSet(numberInLootbox);
    }

    function reveal(uint256 tokenId, string[] calldata names) external override returns (uint256[] memory tokenIds) {
        if (names.length != _numberInLootbox) revert Overflow();
        require(_isApprovedOrOwner(msg.sender, tokenId), "reveal: reveal caller is not owner nor approved");

        tokenIds = _nft.batchMint(msg.sender, names);
        _burn(tokenId);

        return tokenIds;
    }

    function setNFTAddress(address token) external override isOwner {
        if (address(_nft) == token) revert SameAddress();
        _nft = Mayor(token);
        emit NFTAddressSet(token);
    }

    function setMarketplaceAddress(address marketplaceAddress) external override isOwner {
        if (address(_marketplaceAddress) == marketplaceAddress) revert SameAddress();
        _marketplaceAddress = marketplaceAddress;
        emit MarketplaceAddressSet(marketplaceAddress);
    }

    function setNumberInLootbox(uint8 number) external override isOwner {
        if (_numberInLootbox == number) revert SameValue();
        _numberInLootbox = number;
        emit NumberInLootboxSet(number);
    }

    function getNFTAddress() external view override returns (address) {
        return address(_nft);
    }

    function getMarketplaceAddress() external view override returns (address) {
        return _marketplaceAddress;
    }

    function getNumberInLootbox() external view override returns (uint8) {
        return _numberInLootbox;
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
}
