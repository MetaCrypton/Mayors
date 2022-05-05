// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

struct StakingConfig {
    address voteAddress;
    address voucherAddress;
}

struct Stake {
    uint256 startDate;
    uint256 amount;
}
