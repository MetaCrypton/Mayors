// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./NFTStructs.sol";
import "../../common/ownership/OwnableStorage.sol";
import "../../common/erc721/ERC721Storage.sol";

contract NFTStorage is ERC721Storage, OwnableStorage {
    NFTConfig internal _config;

    // counters of common, rare, epic and legendary NFTs
    uint256 internal _commonIdCounter;
    uint256 internal _rareIdCounter;
    uint256 internal _epicIdCounter;
    uint256 internal _legendaryIdCounter;
    // lower borders of rarity ranges
    uint256 internal constant _COMMONMIN = 0;
    uint256 internal constant _RAREMIN = 138000;
    uint256 internal constant _EPICMIN = 188000;
    uint256 internal constant _LEGENDARYMIN = 198000;

    mapping(uint256 => Rarity) internal _rarities;
    mapping(uint256 => uint256) internal _baseHashrates;

    mapping(uint256 => string) internal _names;
    mapping(uint256 => Level) internal _levels;

    // Mapping from token ID to inventory address
    mapping(uint256 => address) internal _inventories;
}
