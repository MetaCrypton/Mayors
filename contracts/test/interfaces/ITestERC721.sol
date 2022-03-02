// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

interface ITestERC721 {
    function mint(string memory tokenURI) external returns (uint256);
}
