// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "../common/ThriftboxStructs.sol";

interface IThriftboxLifecycle {
    function withdrawVotes() external;

    function depositVotesList(Earning[] calldata earnings) external;

    function getVotesDeposit(address player) external view returns (VotesDeposit memory);
}
