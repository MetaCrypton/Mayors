// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "../common/StakingStructs.sol";

interface IStakingMain {
    function stakeVotes(uint256 votesNumber) external;

    function unstakeVotes() external;

    function withdrawVouchersForAll() external;

    function withdrawVouchers(address staker) external;

    function setThreshold(uint256 threshold) external;

    function getThreshold() external view returns (uint256);

    function getVotesAmount() external view returns (uint256 totalAmount);

    function getVouchersAmount() external view returns (uint256 totalAmount);
}
