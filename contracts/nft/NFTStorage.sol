// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./NFTStructs.sol";
import "../common/ownership/Ownable.sol";
import "../common/erc721/ERC721.sol";

contract NFTStorage is ERC721, Ownable {
    NFTConfig internal _config;

    mapping(uint256 => Rarity) internal _rarities;
    mapping(uint256 => uint256) internal _baseHashrates;

    mapping(uint256 => string) internal _names;
    mapping(uint256 => Level) internal _levels;

    // Mapping from token ID to inventory address
    mapping(uint256 => address) internal _inventories;

    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) ERC721(name_, symbol_) Ownable(owner) {}
}
