// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "../common/StakingStructs.sol";

interface IStakingEvents {
    event ConfigUpdated();
    event VotesStaked(uint256 startDate, uint256 amount);
    event VotesUnstaked(address staker, uint256 amount);
    event VouchersMinted(address staker, uint256 amount);
    event StakeRemoved(address staker, uint256 startDate, uint256 amount);
}
