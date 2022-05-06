// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.

pragma solidity ^0.8.0;

import "./common/VoteStorage.sol";
import "./common/VoteErrors.sol";

contract VoteModifiers is VoteStorage {
    modifier isVotingOrOwner() {
        if (msg.sender != _config.votingAddress && msg.sender != _owner) {
            revert VoteErrors.NoPermission();
        }
        _;
    }
}
