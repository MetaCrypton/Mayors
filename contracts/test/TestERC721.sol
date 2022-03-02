// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "../common/erc721/ERC721.sol";
import "./interfaces/ITestERC721.sol";

contract TestERC721 is ITestERC721, ERC721 {
    uint256 public tokenCounter;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        tokenCounter = 0;
    }

    function mint(string memory tokenURI) external override returns (uint256) {
        tokenURI;
        uint256 tokenId = tokenCounter;
        _safeMint(msg.sender, tokenId);
        tokenCounter = tokenCounter + 1;
        return tokenId;
    }
}
