// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

library StakingErrors {
    error WrongMultiplicity();
    error TooOftenStaking();
    error NotEnoughVotes();
    error NotEnoughVotesForStake();
    error SameConfig();
    error StakeDateBeforeNow();
}
