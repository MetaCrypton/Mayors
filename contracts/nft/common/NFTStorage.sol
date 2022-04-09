// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./NFTStructs.sol";
import "../../common/ownership/OwnableStorage.sol";
import "../../common/erc721/ERC721Storage.sol";

contract NFTStorage is ERC721Storage, OwnableStorage {
    NFTConfig internal _config;

    mapping(uint256 => string) internal _seasonURI;

    mapping(uint256 => Rarity) internal _rarities;
    mapping(uint256 => uint256) internal _baseHashrates;

    mapping(uint256 => Level) internal _levels;
}
