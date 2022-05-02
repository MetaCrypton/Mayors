// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "../common/ThriftboxStructs.sol";

interface IThriftboxLifecycle {
    function withdraw() external;

    function depositList(Earning[] calldata earnings) external;

    function balanceOf(address player) external view returns (uint256 votesAmount);

    function getWithdrawalDate(address player) external view returns (uint256 withdrawalDate);
}
