// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "../common/StakingStructs.sol";

interface IStakingMain {
    function changeThreshold(uint256 threshold) external;

    function stakeVotes(uint256 votesNumber) external;

    function unstakeVotes() external;

    function getVouchersAmount() external returns (uint256 totalAmount);

    function getVotesAmount() external returns (uint256 totalAmount);

    function withdrawVouchers(address recipient) external;
}
