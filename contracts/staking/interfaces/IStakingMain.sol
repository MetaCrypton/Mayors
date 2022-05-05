// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "../common/StakingStructs.sol";

interface IStakingMain {
    function stakeVotes(uint256 votesNumber) external;

    function unstakeVotes(uint256 startIndex, uint256 number) external;

    function withdrawVouchers(
        address staker,
        uint256 startIndex,
        uint256 number
    ) external;

    function setThreshold(uint256 threshold) external;

    function getThreshold() external view returns (uint256);

    function getStakesNumber(address staker) external view returns (uint256);

    function getStakersNumber() external view returns (uint256);

    function getVotesAmount(uint256 startIndex, uint256 number) external view returns (uint256 totalAmount);

    function getVouchersAmount(uint256 startIndex, uint256 number) external view returns (uint256 totalAmount);
}
