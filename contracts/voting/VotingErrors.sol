// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

library VotingErrors {
    error Overflow();
    error EmptyArray();
    error WrongMayor();
    error InsufficientBalance();
    error BuildingDuplicate();
    error InactiveObject();
    error VotesBankExceeded();
    error IncorrectVotingPeriod();
    error IncorrectValue();
}