// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

library StakingConstants {
    uint256 internal constant STAKE_STEP = 100;
    uint256 internal constant STAKE_COOLDOWN = 24 hours;
    uint256 internal constant VOTES_PER_VOUCHER = 500;
    uint256 internal constant SECONDS_PER_VOUCHER = 1 days;
}
