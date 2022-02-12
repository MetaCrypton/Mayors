// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./ILootbox.sol";
import "../nft/NFT.sol";
import "../common/interfaces/IERC721.sol";
import "../common/ownership/Ownable.sol";

contract Lootbox is ILootbox, ERC721, Ownable {
    address internal _marketplaceAddress;
    NFT internal _nft;
    uint256 internal _numberInLootbox;

    error SameNFTAddress();
    error SameMarketplaceAddress();
    error SameNumberInLootbox();
    error NotMarketplaceOrOwner();

    modifier isMarketplaceOrOwner() {
        if (msg.sender != _marketplaceAddress && msg.sender != _owner) {
            revert NotMarketplaceOrOwner();
        }
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address owner,
        address token,
        uint256 numberInLootbox
    ) Ownable(owner) ERC721(name_, symbol_) {
        _nft = NFT(token);
        _numberInLootbox = numberInLootbox;
        emit NFTAddressSet(token);
        emit NumberInLootboxSet(numberInLootbox);
    }

    function reveal(uint256 tokenId) external override returns (uint256[] memory tokenIds) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "reveal: reveal caller is not owner nor approved");
        tokenIds = _nft.batchMint(msg.sender, _numberInLootbox);

        _burn(tokenId);
    }

    function setNFTAddress(address token) external override isOwner {
        if (address(_nft) == token) revert SameNFTAddress();
        _nft = NFT(token);
        emit NFTAddressSet(token);
    }

    function setMarketplaceAddress(address marketplaceAddress) external override isOwner {
        if (address(_marketplaceAddress) == marketplaceAddress) revert SameMarketplaceAddress();
        _marketplaceAddress = marketplaceAddress;
        emit MarketplaceAddressSet(marketplaceAddress);
    }

    function setNumberInLootbox(uint256 number) external override isOwner {
        if (_numberInLootbox == number) revert SameNumberInLootbox();
        _numberInLootbox = number;
        emit NumberInLootboxSet(number);
    }

    function getNFTAddress() external view override returns (address) {
        return address(_nft);
    }

    function getMarketplaceAddress() external view override returns (address) {
        return _marketplaceAddress;
    }

    function getNumberInLootbox() external view override returns (uint256) {
        return _numberInLootbox;
    }

    /**
     * @dev Mints `tokenId`. See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function mint(address owner)
        public
        override(ERC721, IERC721Mintable)
        isMarketplaceOrOwner
        returns (uint256 tokenId)
    {
        return super.mint(owner);
    }

    /**
     * @dev Mints `tokenId`. See {ERC721-_safeMint}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function safeMint(address owner)
        public
        override(ERC721, IERC721Mintable)
        isMarketplaceOrOwner
        returns (uint256 tokenId)
    {
        return super.safeMint(owner);
    }

    /**
     * @dev Mints `tokenId`. See {ERC721-_safeMint}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function safeMint(address owner, bytes memory data)
        public
        override(ERC721, IERC721Mintable)
        isMarketplaceOrOwner
        returns (uint256 tokenId)
    {
        return super.safeMint(owner, data);
    }
}
