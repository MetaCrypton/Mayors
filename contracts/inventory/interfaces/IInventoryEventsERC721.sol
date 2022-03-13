// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

interface IInventoryEventsERC721 {
    event DepositERC721(address indexed from, address indexed token, uint256 tokenId);
    event WithdrawERC721(address indexed recipient, address indexed token, uint256 tokenId);
}
