// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

interface IInventoryEventsERC20 {
    event DepositERC20(address indexed from, address indexed token, uint256 amount);
    event WithdrawERC20(address indexed recipient, address indexed token, uint256 amount);
}
