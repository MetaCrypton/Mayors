// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./MarketplaceStructs.sol";
import "../../common/ownership/OwnableStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MarketplaceStorage is ReentrancyGuard, OwnableStorage {
    MarketplaceConfig internal _config;

    Season[] internal _seasons;
    mapping(uint256 => mapping(address => bool)) internal _whiteList;
    mapping(uint256 => mapping(address => uint256)) internal _lootboxesBought;

    mapping(bytes32 => ItemSale) internal _itemSale;
}
