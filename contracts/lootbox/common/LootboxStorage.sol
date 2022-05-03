// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./LootboxStructs.sol";
import "../../common/ownership/OwnableStorage.sol";
import "../../common/erc721/ERC721Storage.sol";

contract LootboxStorage is ERC721Storage, OwnableStorage {
    LootboxConfig internal _config;

    mapping(uint256 => uint256) internal _unlockTimestamp;
    mapping(uint256 => SeasonInfo) internal _seasonInfo;
}
