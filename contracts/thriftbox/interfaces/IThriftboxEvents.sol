// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "../common/ThriftboxStructs.sol";

interface IThriftboxEvents {
    event ConfigUpdated();
    event VotesWithdrawnByPlayer(address player, uint256 lastWithdraw, uint256 amount);
    event VotesDepositedByPlayer(address player, uint256 amount);
    event VotesDepositedTotal(uint256 totalAmount);
}
