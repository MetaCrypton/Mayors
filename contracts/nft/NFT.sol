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

    uint256 internal constant COMMON_RANGE_MAX = 20;
    uint256 internal constant COMMON_RANGE_MIN = 10;

    uint256 internal constant RARE_RANGE_MAX = 55;
    uint256 internal constant RARE_RANGE_MIN = 27;

    uint256 internal constant EPIC_RANGE_MAX = 275;
    uint256 internal constant EPIC_RANGE_MIN = 125;

    uint256 internal constant LEGENDARY_RANGE_MAX = 1400;
    uint256 internal constant LEGENDARY_RANGE_MIN = 650;

    address internal _lootboxAddress;

    mapping(uint256 => Rarity) internal _rarities;
    mapping(uint256 => uint256) internal _baseHashrates;

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

    function calculateRarityAndHashrate(
        uint256 blockNumber,
        uint256 id,
        address owner
    ) public view override returns (Rarity, uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(blockhash(blockNumber), id, owner)));
        uint256 rarityRate = random % LEGENDARY_RATE;
        uint256 randomForRange = (random - (random % 10));
        if (rarityRate < COMMON_RATE) {
            uint256 range = COMMON_RANGE_MAX - COMMON_RANGE_MIN + 1;
            return (Rarity.Common, (randomForRange % range) + COMMON_RANGE_MIN);
        } else if (rarityRate < RARE_RATE) {
            uint256 range = RARE_RANGE_MAX - RARE_RANGE_MIN + 1;
            return (Rarity.Rare, (randomForRange % range) + RARE_RANGE_MIN);
        } else if (rarityRate < EPIC_RATE) {
            uint256 range = EPIC_RANGE_MAX - EPIC_RANGE_MIN + 1;
            return (Rarity.Epic, (randomForRange % range) + EPIC_RANGE_MIN);
        } else if (rarityRate < LEGENDARY_RATE) {
            uint256 range = LEGENDARY_RANGE_MAX - LEGENDARY_RANGE_MIN + 1;
            return (Rarity.Legendary, (randomForRange % range) + LEGENDARY_RANGE_MIN);
        } else {
            revert Overflow();
        }
    }

    function _mintAndSetRarityAndHashrate(address owner) internal returns (uint256) {
        uint256 id = _tokenIdCounter++;
        _mint(owner, id);
        _setRarityAndHashrate(id, owner);
        return id;
    }

    function _setRarityAndHashrate(uint256 id, address owner) internal {
        (Rarity rarity, uint256 hashrate) = calculateRarityAndHashrate(block.number, id, owner);
        _rarities[id] = rarity;
        _baseHashrates[id] = hashrate;
    }
}
