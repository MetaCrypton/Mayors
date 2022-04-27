// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

struct ThriftboxConfig {
    address votesAddress;
    address votingAddress;
}

struct Earning {
    address player;
    uint256 amount;
}

struct VotesDeposit {
    uint256 withdrawalDate;
    uint256 amount;
}