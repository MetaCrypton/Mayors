// SPDX-License-Identifier: MIT
// Modified copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
// Original copyright OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./INFT.sol";
import "../common/erc721/ERC721.sol";
import "../common/ownership/Ownable.sol";

contract NFT is INFT, ERC721, Ownable {
    error NotLootboxOrOwner();
    error SameLootboxAddress();

    address internal _lootboxAddress;

    modifier isLootboxOrOwner() {
        if (msg.sender != _lootboxAddress && msg.sender != _owner) {
            revert NotLootboxOrOwner();
        }
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) Ownable(owner) ERC721(name_, symbol_) {}

    /**
     * @dev Mints several `tokenId`. See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function batchMint(address owner, uint256 number)
        external
        override
        isLootboxOrOwner
        returns (uint256[] memory tokenIds)
    {
        tokenIds = new uint256[](number);
        for (uint i = 0; i < number; i++) {
            tokenIds[i] = super.mint(owner);
        }
        return tokenIds;
    }

    function setLootboxAddress(address lootboxAddress) external override isOwner {
        if (address(_lootboxAddress) == lootboxAddress) revert SameLootboxAddress();
        _lootboxAddress = lootboxAddress;
        emit LootboxAddressSet(lootboxAddress);
    }

    function getLootboxAddress() external view override returns (address) {
        return _lootboxAddress;
    }

    /**
     * @dev Mints `tokenId`. See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function mint(address owner) public override(ERC721, IERC721Mintable) isLootboxOrOwner returns (uint256 tokenId) {
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
        isLootboxOrOwner
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
        isLootboxOrOwner
        returns (uint256 tokenId)
    {
        return super.safeMint(owner, data);
    }
}
