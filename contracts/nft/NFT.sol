// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./NFTConfiguration.sol";
import "./NFTMayor.sol";

contract NFT is NFTMayor, NFTConfiguration {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address owner
    ) {
        _tokenIdCounter = 1;
        _name = name_;
        _symbol = symbol_;
        _seasons.push(Season(baseURI_, 0));
        _owner = owner;
    }
}
