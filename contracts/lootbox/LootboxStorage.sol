// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./LootboxStructs.sol";
import "../common/ownership/Ownable.sol";
import "../common/erc721/ERC721.sol";

contract LootboxStorage is ERC721, Ownable {
    LootboxConfig internal _config;

    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) ERC721(name_, symbol_) Ownable(owner) {}
}
