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
    error SameRarityRates();
    error RateOverflow();
    error CommonRateOverflow();
    error RareRateOverflow();
    error EpicRateOverflow();
    error LegendaryRateOverflow();
    error UnexistingToken();

    uint256 internal constant MAX_RATE = 100;

    address internal _lootboxAddress;
    RarityRates internal _rarityRates;

    mapping(uint256 => Rarity) internal _rarities;

    modifier isLootboxOrOwner() {
        if (msg.sender != _lootboxAddress && msg.sender != _owner) {
            revert NotLootboxOrOwner();
        }
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address owner,
        RarityRates memory rarityRates
    ) Ownable(owner) ERC721(name_, symbol_) {
        if (rarityRates.common > MAX_RATE) revert CommonRateOverflow();
        if (rarityRates.rare > MAX_RATE) revert RareRateOverflow();
        if (rarityRates.epic > MAX_RATE) revert EpicRateOverflow();
        if (rarityRates.legendary > MAX_RATE) revert LegendaryRateOverflow();

        _rarityRates = rarityRates;
        emit RarityRatesSet(rarityRates.common, rarityRates.rare, rarityRates.epic, rarityRates.legendary);
    }

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
            tokenIds[i] = _mintAndSetRarity(owner);
        }
        return tokenIds;
    }

    function setLootboxAddress(address lootboxAddress) external override isOwner {
        if (address(_lootboxAddress) == lootboxAddress) revert SameLootboxAddress();
        _lootboxAddress = lootboxAddress;
        emit LootboxAddressSet(lootboxAddress);
    }

    function setRarityRates(RarityRates calldata rarityRates) external override isOwner {
        if (keccak256(abi.encode(_rarityRates)) == keccak256(abi.encode(rarityRates))) revert SameRarityRates();
        if (rarityRates.common > MAX_RATE) revert CommonRateOverflow();
        if (rarityRates.rare > MAX_RATE) revert RareRateOverflow();
        if (rarityRates.epic > MAX_RATE) revert EpicRateOverflow();
        if (rarityRates.legendary > MAX_RATE) revert LegendaryRateOverflow();

        _rarityRates = rarityRates;
        emit RarityRatesSet(rarityRates.common, rarityRates.rare, rarityRates.epic, rarityRates.legendary);
    }

    function getRarity(uint256 tokenId) external view override returns (Rarity) {
        if (_tokenIdCounter <= tokenId) revert UnexistingToken();
        return _rarities[tokenId];
    }

    function getLootboxAddress() external view override returns (address) {
        return _lootboxAddress;
    }

    function getRarityRates() external view override returns (RarityRates memory) {
        return _rarityRates;
    }

    /**
     * @dev Mints `tokenId`. See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function mint(address owner) public override(ERC721, IERC721Mintable) isLootboxOrOwner returns (uint256 tokenId) {
        return _mintAndSetRarity(owner);
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
        return _safeMintAndSetRarity(owner);
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
        return _safeMintAndSetRarity(owner, data);
    }

    function calculateRarity(
        uint blockNumber,
        uint256 id,
        address owner
    ) public view override returns (Rarity) {
        uint256 number = uint256(keccak256(abi.encodePacked(blockhash(blockNumber), id, owner))) % MAX_RATE;
        if (number < _rarityRates.common) {
            return Rarity.Common;
        } else if (number < _rarityRates.rare) {
            return Rarity.Rare;
        } else if (number < _rarityRates.epic) {
            return Rarity.Epic;
        } else if (number < _rarityRates.legendary) {
            return Rarity.Legendary;
        } else {
            revert RateOverflow();
        }
    }

    function _mintAndSetRarity(address owner) internal returns (uint256) {
        uint256 id = super.mint(owner);
        _setRarity(id, owner);
        return id;
    }

    function _safeMintAndSetRarity(address owner) internal returns (uint256) {
        uint256 id = super.safeMint(owner);
        _setRarity(id, owner);
        return id;
    }

    function _safeMintAndSetRarity(address owner, bytes memory data) internal returns (uint256) {
        uint256 id = super.safeMint(owner, data);
        _setRarity(id, owner);
        return id;
    }

    function _setRarity(uint256 id, address owner) internal {
        _rarities[id] = calculateRarity(block.number, id, owner);
    }
}
