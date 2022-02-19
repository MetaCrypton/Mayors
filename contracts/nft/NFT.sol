// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./INFT.sol";
import "../common/erc721/ERC721.sol";
import "../common/ownership/Ownable.sol";

contract NFT is INFT, ERC721, Ownable {
    error NoPermission();
    error SameAddress();
    error SameRates();
    error WrongRarity();
    error Overflow();
    error UnexistingToken();

    uint8 internal constant COMMON_RATE = 69;
    uint8 internal constant RARE_RATE = 94;
    uint8 internal constant EPIC_RATE = 99;
    uint8 internal constant LEGENDARY_RATE = 100;

    address internal _lootboxAddress;

    mapping(uint256 => Rarity) internal _rarities;

    modifier isExistingToken(uint256 tokenId) {
        if (_tokenIdCounter <= tokenId) revert UnexistingToken();
        _;
    }

    modifier isLootboxOrOwner() {
        if (msg.sender != _lootboxAddress && msg.sender != _owner) {
            revert NoPermission();
        }
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) Ownable(owner) ERC721(name_, symbol_) {}

    function setLootboxAddress(address lootboxAddress) external override isOwner {
        if (address(_lootboxAddress) == lootboxAddress) revert SameAddress();
        _lootboxAddress = lootboxAddress;
        emit LootboxAddressSet(lootboxAddress);
    }

    function getRarity(uint256 tokenId) external view override isExistingToken(tokenId) returns (Rarity) {
        return _rarities[tokenId];
    }

    function getLootboxAddress() external view override returns (address) {
        return _lootboxAddress;
    }

    function calculateRarity(
        uint256 blockNumber,
        uint256 id,
        address owner
    ) public view override returns (Rarity) {
        uint256 number = uint256(keccak256(abi.encodePacked(blockhash(blockNumber), id, owner))) % LEGENDARY_RATE;
        if (number < COMMON_RATE) {
            return Rarity.Common;
        } else if (number < RARE_RATE) {
            return Rarity.Rare;
        } else if (number < EPIC_RATE) {
            return Rarity.Epic;
        } else if (number < LEGENDARY_RATE) {
            return Rarity.Legendary;
        } else {
            revert Overflow();
        }
    }

    function _mintAndSetRarity(address owner) internal returns (uint256) {
        uint256 id = _tokenIdCounter++;
        _mint(owner, id);
        _setRarity(id, owner);
        return id;
    }

    function _safeMintAndSetRarity(address owner) internal returns (uint256) {
        uint256 id = _tokenIdCounter++;
        _safeMint(owner, id);
        _setRarity(id, owner);
        return id;
    }

    function _safeMintAndSetRarity(address owner, bytes memory data) internal returns (uint256) {
        uint256 id = _tokenIdCounter++;
        _safeMint(owner, id, data);
        _setRarity(id, owner);
        return id;
    }

    function _setRarity(uint256 id, address owner) internal {
        _rarities[id] = calculateRarity(block.number, id, owner);
    }
}
