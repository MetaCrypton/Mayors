// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./LootboxStructs.sol";
import "../common/ownership/Ownable.sol";
import "../common/erc721/ERC721.sol";
import "../proxy/Initializable.sol";

contract LootboxStorage is Initializable, ERC721, Ownable {
    LootboxConfig internal _config;

    function __lootboxStorageInit(
        string memory name_,
        string memory symbol_,
        address owner
    ) internal onlyInitializing {
        __erc721Init(name_, symbol_);
        __ownableInit(owner);
    }
}
